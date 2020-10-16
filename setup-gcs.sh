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
buncket_name=apigee-nw-bridge-$project

echo "Create GCS bucket\n"
# create a bucket
gsutil mb -p $project -c STANDARD -l $region -b on gs://apigee-nw-bridge-$project
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "unable to create bucket"
  exit 1
fi

echo "Copy file to GCS bucket\n"
# copy file to bucket
gsutil cp network-bridge.sh gs://apigee-nw-bridge-$project
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "unable to add file to bucket"
  exit 1
fi

echo "Enable public access\n"
# enable full access to file
#gsutil iam ch allUsers:objectViewer gs://apigee-nw-bridge-$project
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi