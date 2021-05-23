terraform {
  required_version = ">= 0.12"
}

variable "region" {
  type        = string
  default     = "us-west1"
  description = "Region in which to create the cluster and run ASM."
}

variable "zone" {
  type        = string
  default     = "us-west1-a"
  description = "Zone in which to create the cluster and run ASM."
}

variable "project" {
  type        = string
  default     = "srinandans-apigee"
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE cluster inside this project."
}

variable "project_services" {
  type = list(string)
  default = [
    "gkehub.googleapis.com",
    "gkeconnect.googleapis.com",
    "meshtelemetry.googleapis.com",
    "meshca.googleapis.com",
    "anthos.googleapis.com",
    "anthosaudit.googleapis.com",
  ]
  description = "List of services to enable on the project."
}

variable "kubernetes_cluster_name" {
  type        = string
  default     = "apigee-mtls"
  description = "Default GKE Cluster Name"
}

variable "apigee_instance_dns" {
  type        = string
  default     = "api.srinandans-apigee.internal"
  description = "DNS entry for the Apigee instance"
}

variable "apigee_external_name" {
  type        = string
  default     = "api.srinandans-apigee.com"
  description = "External DNS name for Apigee"
}