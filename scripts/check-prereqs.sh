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

echo "project id is " $1 
echo "region name is " $2
echo "Apigee endpoint is " $3

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

echo "Check gcloud\n"
gcloud version 2>&1 >/dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "this script depends on gcloud (https://cloud.google.com/sdk/docs/install)"
  exit 1
fi

echo "Set project \n" $project
gcloud config set project $project

#login to the project
gcloud auth login

echo "Check gsutil\n"
gsutil 2>&1 >/dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "this script depends on gsutil (https://cloud.google.com/storage/docs/gsutil_install)"
  exit 1
fi

#echo "Check Private Google Access\n"
#gcloud compute networks subnets describe $vpc_name --region=$region --format="get(privateIpGoogleAccess)" | grep True 2>&1 >/dev/null
#RESULT=$?
#if [ $RESULT -ne 0 ]; then
#  echo "this script requires Private Google Access Configuration (https://cloud.google.com/vpc/docs/configure-private-google-access#config-pga)"
#  exit 1
#fi
