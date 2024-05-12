resource "kubernetes_namespace" "airchat-database" {
  metadata {
    name = "airchat-database"
  }
}


resource "kubernetes_namespace" "longhorn-system" {
  metadata {
    name = "longhorn-system"
  }
}

resource "kubernetes_namespace" "airchat" {
  metadata {
    name = "airchat"
  }

}
