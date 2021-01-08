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
backend_name=apigee-network-bridge-backend

echo "Deleting forwarding rule\n"
gcloud compute forwarding-rules delete apigee-https-lb-rule

echo "Delete LB target https proxy\n"
# Delete Load Balancing Target HTTPS Proxy
gcloud compute target-https-proxies delete apigee-https-proxy

echo "Delete LB URL Map\n"
# Create Load Balancing URL Map
gcloud compute url-maps delete apigee-proxy-map

echo "Delete backend service\n"
# Create Backend Service
gcloud compute backend-services delete $backend_name

echo "Delete Apigee health-check\n"
# Create Health Check
gcloud compute health-checks delete hc-apigee-443

echo "Delete Apigee cert\n"
gcloud compute ssl-certificates delete apigee-ssl-cert

echo "Delete firewall rule\n"
# Create Firewall Rule to allow Load Balancer to access Envoy
gcloud compute firewall-rules delete k8s-allow-lb-to-apigee

echo "Delete reserved IP\n"
# Delete reserved IP Address for Load Balancer
gcloud compute addresses delete lb-ipv4-vip-1