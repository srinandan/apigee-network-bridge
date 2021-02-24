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

# Define the region to setup regional infra like GCE
variable "region1" {
  type        = string
  default     = "us-central1"
  description = "Region to create GCE instances for Apigee."
}

variable "region1_cidr_range" {
  type        = string
  default     = "10.138.0.0/20"
  description = "Region's CIDR range'"
}

# Define the IP Address for Apigee's instance (https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.instances/list)
variable "apigee_region1_endpoint" {
  type        = string
  default     = "10.5.0.2"
  description = "Private IP Address where Apigee is provisioned"  
}

# Pass parameter to the bash script
data "template_file" "apigee-region1-startup-script" {
  template = file("apigee-startup-script.tpl")

  vars = {
    endpoint    = var.apigee_region1_endpoint
  }
}

# Enable Private Google Access configuration
resource "google_compute_subnetwork" "default" {
  provider = google-beta

  name                     = var.gce_subnet
  ip_cidr_range            = var.region1_cidr_range
  region                   = var.region1
  network                  = var.gce_network
  private_ip_google_access = true
}

# Define a GCE Instance template for private VMs
resource "google_compute_instance_template" "apigee-region1" {
  name        = "${var.apigee_mig_prefix}${var.region1}"
  description = "This template is used by Apigee to bridge the network from GCLB to the tenant project."
  region                   = var.region1

  tags = ["apigee"]

  machine_type         = var.gce_instance_type
  can_ip_forward       = true

  scheduling {
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = var.gce_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = var.gce_network
    subnetwork = var.gce_subnet
  }

  metadata = {
    startup-script        = data.template_file.apigee-region1-startup-script.rendered
  }  
}

resource "google_compute_region_instance_group_manager" "apigee-region1" {
  name               = "${var.apigee_mig_prefix}${var.region1}"
  base_instance_name = "${var.apigee_mig_prefix}${var.region1}"
  region               = var.region1

  version {
    instance_template  = google_compute_instance_template.apigee-region1.id
  }

  target_size        = var.gce_min_nodes

  named_port {
    name = "${var.apigee_mig_prefix}-port"
    port = 443
  }
}

resource "google_compute_region_autoscaler" "apigee" {
  name   = "${var.apigee_mig_prefix}${var.region1}"
  region   = var.region1
  target = google_compute_region_instance_group_manager.apigee-region1.id

  autoscaling_policy {
    max_replicas    = var.gce_max_nodes
    min_replicas    = var.gce_min_nodes
    cooldown_period = 90

    cpu_utilization {
      target = 0.75
    }
  }
}
