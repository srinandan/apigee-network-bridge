/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_version = ">= 0.12"
}

variable "project" {
  type        = string
  default     = "srinandans-apigee"
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE and Vault cluster inside this project. If not given, Terraform will generate a new project."
}

variable "apigee_mig_prefix" {
  type        = string
  default     = "apigee-"
  description = "Prefix for Apigee's Managed Instance Group Name"  
}

variable "apigee_cert_path" {
  type        = string
  default     = "tls.crt"
  description = "file path for the TLS certificate"  
}

variable "apigee_key_path" {
  type        = string
  default     = "tls.key"
  description = "file path for the TLS private key"  
}

variable "self_signed_cert_org_name" {
  type        = string
  default     = "Srinandan Sridhar"
  description = "TLS Organization name"  
}

variable "self_signed_cert_common_name" {
  type        = string
  default     = "api.srinandans.com"
  description = "TLS common name"  
}

#
# Apigee Configuration
# -------------------------------

# Define the IP Address for Apigee's instance (https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.instances/list)
variable "apigee_region_endpoint" {
  type        = string
  default     = "10.5.0.2"
  description = "Private IP Address where Apigee is provisioned"  
}

#
# GCE Configuration
# -------------------------------

# Define the region to setup regional infra like GCE
variable "region" {
  type        = string
  default     = "us-west1"
  description = "Region to create GCE instances for Apigee."
}

variable "gce_min_nodes" {
  type        = number
  default     = 1 #change later
  description = "Minimum number of nodes to deploy in a zone for the MIG."
}

variable "gce_max_nodes" {
  type        = number
  default     = 1 #change later
  description = "Maximum number of nodes to deploy in a zone for the MIG."
}

variable "gce_disk_size" {
  type        = number
  default     = 10
  description = "Boot disk size for Kubernetes nodes"
}

variable "gce_instance_type" {
  type        = string
  default     = "e2-micro"
  description = "Instance type to use for the MIG."
}

variable "gce_image" {
  type        = string
  default     = "debian-cloud/debian-10"
  description = "Operating system for the GCE instances."
}

variable "gce_network" {
  type        = string
  default     = "default"
  description = "The network to create GCE instances."
}

variable "gce_subnetwork" {
  type        = string
  default     = "default"
  description = "The subnet to create GCE instances."
}

variable "ilb_subnetwork" {
  type       = string
  default    = "apigee-ilb"
  description = "The subnet for Internal Load Balanacer"
}

# Must at at least /26
variable "ilb_cidr" {
  type       = string
  default    = "192.168.0.0/26"
  description = "The CIDR range for Internal Load Balanacer subnet"
}
