# Setup Apigee Network Bring using Scripts

These instructions help setup a networking bridge to allow Google Cloud External Load Balancers connect to the Apigee service.

## Installation

Setup some environment variables:
AUTH="Authorization: Bearer $(gcloud auth print-access-token)"
PROJECTID=your-apigee-gcp-project-id
REGION=your-gcp-region


APIGEE_INSTANCE_IP: Follow this steps to obtain the Apigee instance IP:

Get the list of instances:

```bash
curl -i -H "$AUTH" -X GET \
  -H "Content-Type:application/json" \
  https://apigee.googleapis.com/v1/organizations/ORG_NAME/instances
```

Get the details of your instance to get your APIGEE_INSTANCE_IP:

```bash
curl -i -H "$AUTH" -X GET \
  -H "Content-Type:application/json" \
  https://apigee.googleapis.com/v1/organizations/ORG_NAME/instances/INSTANCE_NAME
```

The response shows the IP address of the internal load balancer in the host field:


```bash
{
  "name": "eval-us-west1-a",
  "location": "us-west1-a",
  "host": "10.86.0.2",
  "port": "443",
  "state": "ACTIVE"
}
``


```bash
./setup-network.sh $PROJECTID $REGION $APIGEE_INSTANCE_IP
```

Example:

```bash
./setup-network.sh foo us-west1 10.86.0.2
```

NOTE: The VPC Name and subnet is set to `default`. If you wish to use a different network and subnetwork, pass that as the 4th and 5th parameter. Like this

```bash
./setup-network.sh foo us-west1 10.86.0.2 my-network my-subnetwork
```

## Installation Explained

1. [Check Pre-requisites](./check-prereqs.sh)
2. [Create a GCE Instance Group with some IP table rules](./setup-network.sh) (this script will create a group of VMs with some iptables rules to forward traffic from the GLB into Apigee)
4. [Provision a load balancer](./setup-loadbalancer.sh) It adds the MIG as the backend service and creates a GLB with a self-signed certificate

## Validate Installation

1. Go to the GCP console under Compute Engine and check that the VM instance group was created.
1. SSH to one of the VMs in the MIG created previously with the ./setup-network.sh script
3. Run the following command to see the IP tables rules

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

## Clean up

To clean up provisioned instances, run

```bash
./cleanup-network.sh $PROJECTID $REGION
```

___

## Support

This is not an officially supported Google product