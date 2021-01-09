# Setup Apigee Network Bring using Terraform

These instructions help setup a networking bridge via Terraform to allow Google Cloud External Load Balancers connect to the Apigee service.

## Preparation

* Set the `project` variable [here](./variables.tf#L7)
* Set/change variables for a Region
  * These scripts work for Apigee instantiated in a single region. For multi-regions, please see below.
  * Review the [region1.tf](./region1.tf) file. Change the variables `region1` and `apigee_region1_endpoint` as necessary
* TLS Configuration
  * The setup creates a self-signed certificate to demo/experimentation. Please overrides these values: [certificate](./variables.tf#L19) and a [private key](./variables.tf#L25) to provide actual certificates and change the configuration [here](./gcp.tf#L99)

## Installation

```bash
terraform apply
```

___

## Support

This is not an officially supported Google product