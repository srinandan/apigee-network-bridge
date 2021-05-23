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

# Pass parameter to the bash script
data "template_file" "apigee-region-startup-script" {
  template = file("apigee-startup-script.tpl")

  vars = {
    endpoint    = var.apigee_region_endpoint
  }
}

resource "google_compute_subnetwork" "apigee-ilb-subnetwork" {
  provider = google-beta

  name          = var.ilb_subnetwork
  ip_cidr_range = var.ilb_cidr
  region        = var.region
  network       = var.gce_network
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
}

# Obtain a private IP Address
resource "google_compute_address" "apigee" {
  name         = "apigee"
  description  = "The public IP where the Apigee APIs will be exposed"
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.gce_subnetwork
}

# Define a GCE Instance template for private VMs
resource "google_compute_instance_template" "apigee-region" {
  name        = "${var.apigee_mig_prefix}${var.region}"
  description = "This template is used by Apigee to bridge the network from GCLB to the tenant project."

  tags = ["apigee"]

  machine_type         = var.gce_instance_type
  can_ip_forward       = true

  region               = var.region

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
    subnetwork = var.gce_subnetwork
  }

  metadata = {
    startup-script        = data.template_file.apigee-region-startup-script.rendered
  }  
}

resource "google_compute_region_instance_group_manager" "apigee-region" {
  name               = "${var.apigee_mig_prefix}${var.region}"
  base_instance_name = "${var.apigee_mig_prefix}${var.region}"

  region               = var.region

  version {
    instance_template  = google_compute_instance_template.apigee-region.id
  }

  target_size        = var.gce_min_nodes

  named_port {
    name = "${var.apigee_mig_prefix}-port"
    port = 443
  }
}

# Healthcheck Apigee endpoint
resource "google_compute_health_check" "apigee-health-check" {
  name = "apigee"

  https_health_check {
    port         = "443"
    request_path = "/healthz/ingress"
  }
}

# Define auto scaler
resource "google_compute_region_autoscaler" "apigee" {
  name   = "${var.apigee_mig_prefix}${var.region}"
  region   = var.region
  target = google_compute_region_instance_group_manager.apigee-region.id

  autoscaling_policy {
    max_replicas    = var.gce_max_nodes
    min_replicas    = var.gce_min_nodes
    cooldown_period = 90

    cpu_utilization {
      target = 0.75
    }
  }
}

# Create regional backed
resource "google_compute_region_backend_service" "apigee" {
  provider      = google-beta   

  name                            = "apigee-backend-service"
  region                          = var.region
  port_name                       = "${var.apigee_mig_prefix}-port"
  health_checks                   = [google_compute_health_check.apigee-health-check.id]
  load_balancing_scheme           = "INTERNAL_MANAGED"
  timeout_sec                     = 10
  connection_draining_timeout_sec = 300
  
  backend {
    group           = google_compute_region_instance_group_manager.apigee-region.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

# Create URL Map
resource "google_compute_region_url_map" "apigee" {
  name            = "apigee"
  description     = "Load Balancer for Apigee"
  region          = var.region
  default_service = google_compute_region_backend_service.apigee.id
}

# Create target https proxy
resource "google_compute_region_target_https_proxy" "apigee" {
  name             = "apigee"
  url_map          = google_compute_region_url_map.apigee.id
  region           = var.region
  ssl_certificates = [google_compute_region_ssl_certificate.apigee.id]
}

# create a regional L7 load balancer
resource "google_compute_forwarding_rule" "apigee" {
  provider              = google-beta
  depends_on            = [google_compute_subnetwork.apigee-ilb-subnetwork]
  name                  = "apigee"
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  target                = google_compute_region_target_https_proxy.apigee.id
  port_range            = "443"
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.apigee.address
  network               = var.gce_network
  subnetwork            = var.gce_subnetwork
}