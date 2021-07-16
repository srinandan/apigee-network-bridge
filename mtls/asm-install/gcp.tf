// Configure the Google Cloud provider
provider "google" {
 project     = var.project
 region      = var.region
}

provider "google-beta" {
  region  = var.region
  project = var.project
}

# This is the default compute engine service. Since the private cluster is 
# using the default service account, we are going to import the SA
data "google_project" "project" {}

# Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = var.project
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

data "google_container_cluster" "apigee-mtls" {
  name = var.kubernetes_cluster_name
  location = var.zone

}

data "google_compute_address" "apigee" {
  name = "apigee"
}

data "template_file" "gateway-manifest" {
  template = "${file("gateway.tpl")}"

  vars = {
    apigee_instance_dns     = var.apigee_instance_dns
    apigee_external_name    = var.apigee_external_name
  }
}

data "template_file" "virtualservice-manifest" {
  template = "${file("virtualservice.tpl")}"

  vars = {
    apigee_instance_dns     = var.apigee_instance_dns
    apigee_external_name    = var.apigee_external_name
  }
}

data "template_file" "serviceentry-manifest" {
  template = "${file("serviceentry.tpl")}"

  vars = {
    apigee_instance_dns     = var.apigee_instance_dns
    apigee_external_name    = var.apigee_external_name
  }
}

data "template_file" "destinationrules-manifest" {
  template = "${file("destinationrules.tpl")}"

  vars = {
    apigee_instance_dns     = var.apigee_instance_dns
    apigee_external_name    = var.apigee_external_name
  }
}

module "asm" {
  source           = "terraform-google-modules/kubernetes-engine/google//modules/asm"

  project_id             = var.project
  cluster_name           = var.kubernetes_cluster_name
  location               = var.zone
  cluster_endpoint       = data.google_container_cluster.apigee-mtls.endpoint
  # managed                = false 
  enable_all             = false
  enable_cluster_roles   = true
  enable_cluster_labels  = true
  enable_gcp_apis        = true
  enable_gcp_iam_roles   = false
  enable_gcp_components  = true
  enable_registration    = false  
  managed_control_plane  = false #can be changed to true
  skip_validation        = true
}

resource "kubectl_manifest" "gateway" {
  yaml_body = data.template_file.gateway-manifest.rendered
}

resource "kubectl_manifest" "virtualservice" {
  yaml_body = data.template_file.virtualservice-manifest.rendered
}

resource "kubectl_manifest" "serviceentry" {
  yaml_body = data.template_file.serviceentry-manifest.rendered
}

resource "kubectl_manifest" "destinationrules" {
  yaml_body = data.template_file.destinationrules-manifest.rendered
}

#NOTE: This part has not been tested.
module "kubectl" {
  source = "terraform-google-modules/gcloud/google//modules/kubectl-wrapper"
  use_existing_context    = true
  project_id              = var.project
  cluster_name            = var.kubernetes_cluster_name
  cluster_location        = var.zone
  kubectl_create_command  = "kubectl patch service -n istio-system istio-ingressgateway -p '{\"spec\":{\"loadBalancerIP\":\"${data.google_compute_address.apigee.address}\"}}'"
  kubectl_destroy_command = "kubectl patch service -n istio-system istio-ingressgateway -p '{\"spec\":{\"loadBalancerIP\":\"\"}}'"
}
