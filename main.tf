terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = ">=2.5.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.6"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.2.0"
    }
  }
}

provider "cloudinit" {}
provider "null" {}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
}

