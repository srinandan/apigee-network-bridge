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

#
# GCE Configuration
# -------------------------------

variable "gce_min_nodes" {
  type        = number
  default     = 3
  description = "Minimum number of nodes to deploy in a zone for the MIG."
}

variable "gce_max_nodes" {
  type        = number
  default     = 6
  description = "Maximum number of nodes to deploy in a zone for the MIG."
}

variable "gce_disk_size" {
  type        = number
  default     = 25
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
