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

### VPC Peering

If you haven't done so already, use this script to configure Service Networking to peer with Apigee

```bash
./setup-peering.sh $project-id
```

## Installation

* [Install via scripts](./scripts)
* [Install via Terraform](./tform)

___

## Support

This is not an officially supported Google product
