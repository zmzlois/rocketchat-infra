provider "kubernetes" {
  config_path    = var.config_path
  config_context = var.config_context
}

provider "helm" {
  kubernetes {

    config_path    = var.config_path
    config_context = var.config_context
  }
}

variable "hosts" {
  type = list(string)
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "minio"
  }
}

resource "helm_release" "minio" {
  chart     = "oci://registry-1.docker.io/bitnamicharts/minio"
  name      = "minio"
  namespace = kubernetes_namespace.this.metadata[0].name

  values = [yamlencode({
    ingress = {
      enabled = true
      annotations = {
        "cert-manager.io/cluster-issuer" = "cert-manager"
      }
      hosts = [for host in var.hosts : {
        host  = host
        paths = ["/"]
      }]
    }
  })]
}


