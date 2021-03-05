# Setup Apigee Network Bring using Scripts

These instructions help setup a networking bridge to allow Google Cloud External Load Balancers connect to the Apigee service.

## Installation

```bash
./setup-network.sh $PROJECTID $REGION $APIGEE_INSTANCE_IP
```

Example:

```bash
./setup-network.sh foo us-west1 10.5.8.2
```

NOTE: The VPC Name and subnet is set to `default`. If you wish to use a different network and subnetwork, pass that as the 4th and 5th parameter. Like this

```bash
./setup-network.sh foo us-west1 10.5.8.2 my-network my-subnetwork
```

## Installation Explained

1. [Check Pre-requisites](./check-prereqs.sh)
2. [Create a GCS Bucket](./setup-gcs.sh) and store VM startup script there
3. [Create a GCE Instance template](./setup-mig.sh) (with the startup script created previously) and managed instance group with that template. 
4. [Provision a load balancer](./setup-loadbalancer.sh) and add the MIG as the backend service

## Validate Installation

1. Use (or create) a GCE VM with an external IP address in the same REGION as the managed instance group.
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

## Clean up

To clean up provisioned instances, run

```bash
./cleanup-network.sh $PROJECTID $REGION
```

___

## Support

This is not an officially supported Google product