terraform {
  required_version = ">= 0.12"

  required_providers {
    google = "~> 3.0"

    kubernetes = {
        source        = "hashicorp/kubernetes"
        version       = "1.13.2"
      }

    kubectl = {
      source          = "gavinbunney/kubectl"
      version         = "1.9.1"
    }
        
  }
}