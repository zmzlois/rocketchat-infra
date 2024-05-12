

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
        "kuberentes.io/ingress-class"    = "traefik"
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
      hosts = [for host in var.hosts : {
        host  = host
        paths = ["/"]
      }]
    }
  })]
}


