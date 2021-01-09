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

// Configure the Google Cloud provider
provider "google" {
 project     = var.project
}

provider "google-beta" {
  project = var.project
}

data "google_compute_image" "apigee_image" {
  family  = "debian-10"
  project = "debian-cloud"
}

# Obtain a public IP Address
resource "google_compute_global_address" "apigee" {
  name         = "apigee"
  description  = "The public IP where the Apigee APIs will be exposed"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# Create Firewall Rule to allow Load Balancer to access Envoy
resource "google_compute_firewall" "apigee" {
  name        = "apigee"
  description = "Allow incoming from GLB on TCP port 443 to Apigee Proxy"

  network     = var.gce_network

  source_ranges = [ "130.211.0.0/22", "35.191.0.0/16" ]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = [ "apigee" ]
}

# Generate a private key
resource "tls_private_key" "apigee-example" {
  algorithm   = "RSA"
}

# Generate a self signed certificate for the example
resource "tls_self_signed_cert" "apigee-example" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.apigee-example.private_key_pem

  subject {
    common_name  = var.self_signed_cert_common_name
    organization = var.self_signed_cert_org_name
  }

  validity_period_hours = 8760

  is_ca_certificate = true

  dns_names = [
    var.self_signed_cert_common_name
  ]

  #ip_addresses = [
  #  google_compute_global_address.apigee.address
  #]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  depends_on = [ 
    tls_private_key.apigee-example
  ]
}

# Use the self signed certificate from the example
resource "google_compute_ssl_certificate" "apigee" {
  name_prefix = "apigee"
  description = "TLS certificates for APIs exposed by Apigee"
  #private_key = file(var.apigee_key_path)
  private_key = tls_private_key.apigee-example.private_key_pem
  #certificate = file(var.apigee_cert_path)
  certificate = tls_self_signed_cert.apigee-example.cert_pem

  lifecycle {
    create_before_destroy = true
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

# Create URL Map
resource "google_compute_url_map" "apigee" {
  name = "apigee"
  description = "Load Balancer for Apigee"
  default_service = google_compute_backend_service.apigee.id
}

# 
resource "google_compute_target_https_proxy" "apigee" {
  name             = "apigee"
  url_map          = google_compute_url_map.apigee.id
  ssl_certificates = [google_compute_ssl_certificate.apigee.id]
}

# 
resource "google_compute_global_forwarding_rule" "apigee" {
  provider   = google-beta
  name       = "apigee"
  target     = google_compute_target_https_proxy.apigee.id
  port_range = "443"
  ip_address = google_compute_global_address.apigee.address
}

