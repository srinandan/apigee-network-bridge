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
endpoint=$3
vpc_name=$4
subnet=$5
mig_name=apigee-network-bridge-$region-mig

echo "Create GCE instance template\n"
# create a template
gcloud compute instance-templates create $mig_name \
  --project $project --region $region --network $vpc_name --subnet $subnet \
  --tags=https-server,apigee-envoy-proxy,gke-apigee-proxy \
  --machine-type e2-micro --image-family ubuntu-minimal-1804-lts \
  --image-project ubuntu-os-cloud --boot-disk-size 10GB \
  --preemptible --no-address --can-ip-forward \
  --metadata=ENDPOINT=$3,startup-script='#!/bin/sh
sudo su - 

endpoint=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/ENDPOINT -H "Metadata-Flavor: Google")

sysctl -w net.ipv4.ip_forward=1
sysctl -ew net.netfilter.nf_conntrack_buckets=1048576
sysctl -ew net.netfilter.nf_conntrack_max=8388608


iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination $endpoint

exit 0'
  
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
