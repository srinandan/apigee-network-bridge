# Apigee Network Bridge - for L7 ILB

This use case explore a variation of the pattern explored previously. In the previous pattern, we used an L7 External Load Balancer. In this case we will setup an L7 Internal Load Balancer.

When an Apigee Instance is provisioned, it is provisioned with a self-signed cert. The CA file for the certificate can be found when querying the org entity: `GET https://apigee.googleapis.com/v1/{name=organizations/*}`

Output:

```sh
...
"caCertificate": string
...
```

Applications running in GCP (assuming they access the Instance IP directly) will need to trust this CA cert as part of their application. Customers may want to use their own certificate instead of the Apigee generated one. In such cases customers can setup a L7 Internal Load Balancer (which hosts the customer managed certificate and terminates TLS) which then forwards the traffic to  the Apigee instance.

## Setup

This script uses Terraform. Before installation, please don't forget to update the [variables](./variables.tf). To install the setup:

```bash
terraform apply
```