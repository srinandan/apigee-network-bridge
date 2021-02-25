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

if [ -z "$2" ]
  then
    network=$2
else
    network=default
fi

if [ -z "$3" ]
  then
    subnet=$3
else
    subnet=default
fi

# configure service networking

gcloud compute addresses create google-svcs --global \ 
    --prefix-length=16 --description="peering range for Google services" \ 
    --network=$network --subnet=$subnet --purpose=VPC_PEERING --project=$project

# This establishes the one-time, private connection between the customer project default VPC network and Google tenant projects.
 
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \ 
    --network=$network --subnet=$subnet --ranges=google-svcs --project=$project