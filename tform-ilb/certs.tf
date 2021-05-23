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

  ip_addresses = [
    google_compute_address.apigee.address
  ]

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
resource "google_compute_region_ssl_certificate" "apigee" {
  name_prefix = "apigee"
  description = "TLS certificates for APIs exposed by Apigee"

  region      = var.region

  # if you are providing a key/cert, uncomment the following two lines
  #private_key = file(var.apigee_key_path)
  #certificate = file(var.apigee_cert_path)

  # if using self signed certificates, uncomment the following two lines
  private_key = tls_private_key.apigee-example.private_key_pem
  certificate = tls_self_signed_cert.apigee-example.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}