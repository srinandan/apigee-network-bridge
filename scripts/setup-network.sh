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

network="default"
subnet="default"

#**
# @brief    Displays usage details.
#
usage() {
    echo -e "$*\n usage: $(basename "$0")" \
        "-o <org> -e <env> -c <component> -n <namespace>\n" \
        "example: $(basename "$0") -p my-proj -r us-west1 -i 10.75.0.2 \n" \
        "Parameters:\n" \
        "-p --prj       : GCP Project Id     (mandatory parameter)\n" \
        "-r --reg       : GCP Region Name    (mandatory parameter)\n" \
        "-i --ip        : Apigee Instance IP (mandatory parameter)\n" \
        "-n --network   : Network name       (optional parameter; default is default)\n" \
        "-s --subnet    : Subnet name        (optional parameter; default is default)\n"
    exit 1
}

### Start of mainline code ###

PARAMETERS=()
while [[ $# -gt 0 ]]
do
    param="$1"

    case $param in
        -p|--prj)
        project="$2"
        shift
        shift
        ;;
        -r|--reg)
        region="$2"
        shift
        shift
        ;;
        -i|--ip)
        apigeeip="$2"
        shift
        shift
        ;;
        -n|--network)
        network="$2"
        shift
        shift
        ;;
        -s|--subnet)
        subnet="$2"
        shift
        shift
        ;;        
        *)
        PARAMETERS+=("$1")
        shift
        ;;
    esac
done

set -- "${PARAMETERS[@]}"

./check-prereqs.sh $project $region $apigeeip
RESULT=$?
if [ $RESULT -ne 0 ]; then
  usage
  exit 1
fi

./setup-mig.sh $project $region $apigeeip $network $subnet
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

./setup-loadbalancer.sh $project $region $network $subnet
RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit 1
fi

exit 0
