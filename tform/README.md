# Setup Apigee Network Bring using Terraform

These instructions help setup a networking bridge via Terraform to allow Google Cloud External Load Balancers connect to the Apigee service.

## Preparation

* Set the `project` variable [here](./variables.tf#L7)
* Set/change variables for a Region
  * These scripts work for Apigee instantiated in a single region. For multi-regions, please see below.
  * Review the [region1.tf](./region1.tf) file. Change the variables `region1` and `apigee_region1_endpoint` as necessary
* TLS Configuration
  There are three options to create a TLS certificate:
  * *Default*: This script provisions a [GCP Managed TLS Certificate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) using the [xip.io](http://xip.io/) provider. This is appropriate for demo/experimentation.
  * If you do not wish to the use the xip provider, you can use a self-signed certificate. Please overrides these values: [certificate](./variables.tf#L19) and a [private key](./variables.tf#L25) to provide actual certificates and change the configuration [here](./gcp.tf#L99)
  * If you are providing a key/cert, please overrides these values: [apigee_cert_path](./variables.tf#L33) and a [apigee_key_path](./variables.tf#L39) and uncomment lines [here](./gcp.tf#L99)

## Installation

```bash
terraform apply
```

___

## Support

This is not an officially supported Google product