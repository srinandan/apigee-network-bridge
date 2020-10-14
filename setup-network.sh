#!/bin/sh
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo $1
echo $2
echo $3

echo "project id is " $1 
echo "region name is " $2
echo "Apigee endpoint is " $2

if [ -z "$1" ]
  then
    echo "project id is a mandatory parameter."
    exit 1
fi

if [ -z "$2" ]
  then
    echo "region name is a mandatory parameter."
    exit 1
fi

if [ -z "$3" ]
  then
    echo "Apigee endpoint is a mandatory parameter. It can be obtained by /v1/organizations/{org}/instances/{instance-name}"
    exit 1
fi

project=$1
region=$2
vpc_name=default
mig_name=apigee-network-bridge-$region-mig
buncket_name=apigee-nw-bridge-$project

echo $mig_name

echo "Check gcloud\n"
gcloud version 2>&1 >/dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "this script depends on gcloud (https://cloud.google.com/sdk/docs/install)"
  exit 1
fi

echo "Set project \n" $project
gcloud config set project $project

#TODO: remove later
#gcloud auth login

echo "Check gsutil\n"
gsutil 2>&1 >/dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "this script depends on gsutil (https://cloud.google.com/storage/docs/gsutil_install)"
  exit 1
fi

echo "Check Private Google Access\n"
gcloud compute networks subnets describe $vpc_name --region=$region --format="get(privateIpGoogleAccess)" | grep True 2>&1 >/dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "this script requires Private Google Access Configuration (https://cloud.google.com/vpc/docs/configure-private-google-access#config-pga)"
  exit 1
fi

echo "Create GCS bucket\n"
# create a bucket
gsutil mb -p $project -c STANDARD -l $region -b on gs://apigee-nw-bridge-$project

echo "Copy file to GCS bucket\n"
# copy file to bucket
gsutil cp network-bridge.sh gs://apigee-nw-bridge-$project

echo "Enable public access\n"
# enable full access to file
#gsutil iam ch allUsers:objectViewer gs://apigee-nw-bridge-$project
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi

echo "Create GCE instance template\n"
# create a template
gcloud compute instance-templates create $mig_name \
  --project $project --region $region --network $vpc_name \
  --tags=https-server,apigee-envoy-proxy,gke-apigee-proxy \
  --machine-type e2-micro --image-family ubuntu-minimal-1804-lts \
  --image-project ubuntu-os-cloud --boot-disk-size 10GB \
  --preemptible --no-address \
  --metadata=ENDPOINT=$3,startup-script-url=gs://apigee-nw-bridge-$project/network-bridge.sh
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi  

echo "Create GCE Managed Instance Group\n"
# Create Instance Group
# NOTE: Change min replicas if necessary
gcloud compute instance-groups managed create $mig_name \
    --project $project --base-instance-name apigee-nw-bridge \
    --size 1 --template $mig_name --region $region
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi

echo "Create GCE auto-scaling\n"
# Configure Autoscaling
# NOTE: Change max replicas if necessary
gcloud compute instance-groups managed set-autoscaling $mig_name \
    --project $project --region $region --max-num-replicas 3 \
    --target-cpu-utilization 0.75 --cool-down-period 90
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi

# Defined Named Port
gcloud compute instance-groups managed set-named-ports $mig_name \
    --project $project --region $region --named-ports https:443
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi

while true; do
    read -p "Do you to proceed with the creation and configuration of GCLB?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 0;;
        * ) echo "Please enter yes or no.";;
    esac
done

# Reserve IP Address for Load Balancer
gcloud compute addresses create lb-ipv4-vip-1 \
    --project $project --ip-version=IPV4 --global

# Get Reserved IP Address
lb_ip=$(gcloud compute addresses describe lb-ipv4-vip-1 \
    --project $project --format="get(address)" --global)

echo "Reserved IP: " $lb_ip

# Create Firewall Rule to allow Load Balancer to access Envoy
gcloud compute firewall-rules create k8s-allow-lb-to-apigee \
    --description "Allow incoming from GLB on TCP port 443 to Apigee Proxy" \
    --project $project --network $vpc_name --allow=tcp:443 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=gke-apigee-proxy

echo "Check openssl\n"
openssl 2>&1 >/dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "this script depends on openssl to generate self-signed certs"
  exit 1
fi

# create key and cert pair
openssl genrsa -out tls.key 2048
openssl req -x509 -new -nodes -key tls.key -subj "/CN=api.srinandans.com" -days 3650 -out tls.crt

echo "Upload certs\n"
# upload certs to GCP
gcloud compute ssl-certificates create apigee-ssl-cert \
    --project $project \
    --certificate=tls.crt \
    --private-key=tls.key

echo "Configure a health-check\n"
# Create Health Check
gcloud compute health-checks create https hc-apigee-443 \
    --project $project --port 443 --global \
    --request-path /healthz/ingress

echo "Create backend service\n"
# Create Backend Service
gcloud compute backend-services create apigee-network-bridge-backend \
    --project $project --protocol HTTPS \
    --health-checks hc-apigee-443 --port-name https \
    --timeout 60s --connection-draining-timeout 300s --global

echo "Add instance group to backend service\n"
# Add Instance Group to Backend Service
gcloud compute backend-services add-backend apigee-network-bridge-backend \
    --project $project --instance-group $mig_name \
    --instance-group-region $region \
    --balancing-mode UTILIZATION --max-utilization 0.8 --global

echo "Create LB URL Map\n"
# Create Load Balancing URL Map
gcloud compute url-maps create apigee-proxy-map \
    --project $project --default-service apigee-network-bridge-backend

echo "Create LB target https proxy\n"
# Create Load Balancing Target HTTPS Proxy
gcloud compute target-https-proxies create apigee-https-proxy \
    --project $project --url-map apigee-proxy-map \
    --ssl-certificates apigee-ssl-cert

# Create Global Forwarding Rule
gcloud compute forwarding-rules create apigee-https-lb-rule \
    --project $project --address lb-ipv4-vip-1 --global \
    --target-https-proxy apigee-https-proxy --ports 443

echo "Setup complete. Try api as curl https://$lb_ip -kv\n"

exit 0