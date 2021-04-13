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

project=$1
region=$2
vpc_name=$3
subnet=$4

backend_name=apigee-network-bridge-backend

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
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "failed to create health check"
  exit 1
fi

echo "Create backend service\n"
# Create Backend Service
gcloud compute backend-services create $backend_name \
    --project $project --protocol HTTPS \
    --health-checks hc-apigee-443 --port-name https \
    --timeout 60s --connection-draining-timeout 300s --global
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "failed to create backend service"
  exit 1
fi


echo "Add instance group to backend service\n"
# Add Instance Group to Backend Service
gcloud compute backend-services add-backend $backend_name \
    --project $project --instance-group $mig_name \
    --instance-group-region $region \
    --balancing-mode UTILIZATION --max-utilization 0.8 --global
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "failed to add backend service"
  exit 1
fi

echo "Create LB URL Map\n"
# Create Load Balancing URL Map
gcloud compute url-maps create apigee-proxy-map \
    --project $project --default-service $backend_name
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "failed to create url map"
  exit 1
fi


echo "Create LB target https proxy\n"
# Create Load Balancing Target HTTPS Proxy
gcloud compute target-https-proxies create apigee-https-proxy \
    --project $project --url-map apigee-proxy-map \
    --ssl-certificates apigee-ssl-cert
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "failed to create target proxy"
  exit 1
fi

echo "Create forwarding rule\n"
# Create Global Forwarding Rule
gcloud compute forwarding-rules create apigee-https-lb-rule \
    --project $project --address lb-ipv4-vip-1 --global \
    --target-https-proxy apigee-https-proxy --ports 443
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "failed to add forwarding rule"
  exit 1
fi    

echo "Load balancer complete. Try api as curl https://$lb_ip -kv\n"