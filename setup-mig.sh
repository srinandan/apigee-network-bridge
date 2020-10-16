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
mig_name=apigee-network-bridge-$region-mig

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
