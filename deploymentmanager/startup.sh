#!/bin/sh
# Copyright 2021 Google LLC
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

######
# This file will be uploaded to the GCS bucket gs://bap-marketplace/apigee-network-bridge/startup.sh
######
sudo su -

apt-get install jq -y

#Install Cloud Monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
bash add-monitoring-agent-repo.sh
apt-get update -y
apt-get install stackdriver-agent -y

#Install Cloud Logging agent
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh
apt-get update -y
apt-get install google-fluentd google-fluentd-catch-all-config-structured -y

project=$(curl -s http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
echo "project: $project"
token=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token -H "Metadata-Flavor: Google" | jq .access_token)
region=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | awk '{split($0,a,"/"); print a[4]}' | awk '{print substr($0,1,length($0)-2)}')
echo "region: $region"
endpoint=$(curl -H "Authorization: Bearer $token" https://apigee.googleapis.com/v1/organizations/$project/instances| jq -r -c ".instances[] | select(.location | contains(\"$region\")) | .host")
# If the endpoint is empty because the regions do not match we will use the host from the first instance in the list.
if [ -z "$endpoint" ]
then
      endpoint=$(curl -H "Authorization: Bearer $token" https://apigee.googleapis.com/v1/organizations/$project/instances| jq -r -c ".instances[0] | .host")
fi

echo "endpoint: $endpoint"

if [ -x /bin/firewall-cmd ]
then
   sysctl -w net.ipv4.ip_forward=1
   firewall-cmd --permanent --add-masquerade
   firewall-cmd --permanent --add-forward-port=port=443:proto=tcp:toaddr=$endpoint
else
   sysctl -w net.ipv4.ip_forward=1
   iptables -t nat -A POSTROUTING -j MASQUERADE
   iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination $endpoint
fi

sysctl -ew net.netfilter.nf_conntrack_buckets=1048576
sysctl -ew net.netfilter.nf_conntrack_max=8388608

exit 0