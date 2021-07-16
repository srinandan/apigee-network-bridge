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
  default     = "project-id"
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE cluster inside this project."
}

variable "network" {
  type        = string
  default     = "default"
  description = "The network peered with Apigee"
}

variable "subnetwork" {
  type        = string
  default     = "default"
  description = "The subnet used by the load balancer"
}

# Define the IP Address for Apigee's instance (https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.instances/list)
variable "apigee_region_endpoint" {
  type        = string
  #default     = "10.5.0.2"
  default     = "10.89.180.2"
  description = "Private IP Address where Apigee is provisioned"  
}

variable "project_services" {
  type = list(string)
  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
  description = "List of services to enable on the project."
}

variable "crypto_iam_roles" {
  type = list(string)
  default = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  ]
  description = "List of iam roles."
}

#
# GKE options
# ------------------------------

variable "kubernetes_cluster_name" {
  type        = string
  default     = "apigee-mtls"
  description = "Default GKE Cluster Name"
}

variable "kubernetes_instance_type" {
  type        = string
  default     = "e2-standard-4"
  description = "Instance type to use for the nodes."
}

variable "kubernetes_release_channel" {
  type    = string
  default = "REGULAR"
}

variable "kubernetes_logging_service" {
  type        = string
  default     = "logging.googleapis.com/kubernetes"
  description = "Name of the logging service to use. By default this uses the new Stackdriver GKE beta."
}

variable "kubernetes_monitoring_service" {
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
  description = "Name of the monitoring service to use. By default this uses the new Stackdriver GKE beta."
}

variable "kubernetes_min_nodes" {
  type        = number
  default     = 1 # change later
  description = "Minimum number of nodes to deploy in a zone of the Kubernetes cluster."
}

variable "kubernetes_max_nodes" {
  type        = number
  default     = 3 # change later
  description = "Maximum number of nodes to deploy in a zone of the Kubernetes cluster."
}

variable "kubernetes_disk_size" {
  type        = number
  default     = 25
  description = "Boot disk size for Kubernetes nodes"
}

variable "kubernetes_masters_ipv4_cidr" {
  type        = string
  default     = "172.16.0.32/28"
  description = "IP CIDR block for the Kubernetes master nodes. This must be exactly /28 and cannot overlap with any other IP CIDR ranges."  
}

#
# KMS options
# ------------------------------

variable "kms_key_ring" {
  type        = string
  default     = "apigee-key-ring"
  description = "String value to use for the name of the KMS key ring. This exists for backwards-compatability for users of the existing configurations. Please use kms_key_ring_prefix instead."
}

variable "kms_crypto_key" {
  type        = string
  default     = "apigee-key"
  description = "String value to use for the name of the KMS crypto key."
}
