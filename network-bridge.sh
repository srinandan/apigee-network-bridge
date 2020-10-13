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

sudo su - 

endpoint=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/$ENDPOINT -H "Metadata-Flavor: Google")

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

exit 0
