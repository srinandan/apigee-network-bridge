# apigee-network-bridge

This repo creates a network brdge between [Google Cloud Load Balancer](https://cloud.google.com/load-balancing/docs/https) and [Apigee public cloud](https://cloud.google.com/apigee/docs) running on GCP.

## Architecture

The Apigee service when provisioned in GCP, it is available as a private service (behind an internal load balancer). 

<img src="./ngsaas-networking.png" align="center" height="400" width="400">

This repo contains scripts that provisions a managed instance group with NAT rules to forward API requests from an external load balancer to Apigee's internal load balancer. 

## Prerequisites

* An Apigee org is provisioned. See [here](https://cloud.google.com/apigee/docs/api-platform/get-started/overview) for instructions. 
* gcloud CLI is installed
* gsutil CLI is installed
* The GCP region which has the Apigee runtime instance enabled, has [Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access#config-pga) enabled

To know which runtime instances you have, run the command:

```bash
token="$(gcloud auth print-access-token)"
curl -H "Authorization: Bearer $token" https://apigee.googleapis.com/v1/organizations/{org}/instances
```

## Installation

```bash
./setup-network.sh $project-id $region $apigee-instance-ip
```

Example:

```bash
./setup-network.sh foo us-west1 10.5.8.2
```

### Installation Explained

1. [Check Pre-requisites](./check-prereqs.sh)
2. [Create a GCS Bucket](./setup-gcs.sh) and store VM startup script there
3. [Create a GCE Instance template](./setup-mig.sh) (with the startup script created previously) and managed instance group with that template. 
4. [Provision a load balancer](./setup-loadbalancer.sh) and add the MIG as the backend service

### Validate Installation

1. Use (or create) a GCE VM with an external IP address in the same region as the managed instance group.
2. ssh to the GCE VM and then ssh to one of the VMs in the MIG
3. Run the command to see the IP tables rules

```bash
sudo iptables -t nat -n -v -L
```

NOTE: The command takes a few mins. Here is an example output

```bash
Chain PREROUTING (policy ACCEPT 5 packets, 2043 bytes)
 pkts bytes target     prot opt in     out     source               destination         
33849 2031K DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443 to:10.5.8.2

Chain INPUT (policy ACCEPT 5 packets, 2043 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 3521 packets, 240K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
37370 2271K MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0     
```

___

## Support

This is not an officially supported Google product