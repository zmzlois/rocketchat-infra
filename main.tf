
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">=1.7.0"
    }
  }

}

provider "kubernetes" {

  config_path    = var.config_path
  config_context = var.config_context
}

provider "kubectl" {
  config_path    = var.config_path
  config_context = var.config_context
}

provider "helm" {
  kubernetes {

    config_path    = var.config_path
    config_context = var.config_context
  }
}


