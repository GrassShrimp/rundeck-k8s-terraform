resource "kubernetes_persistent_volume" "mysql_pv" {
  metadata {
    name = "mysql-pv"
  }

  spec {
    capacity = {
      storage = "3Gi"
    }

    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/kubernetes/mysql-data"
      }
    }

    storage_class_name = var.storageClassName
  }  
}

resource "kubernetes_persistent_volume_claim" "mysql_pv_claim" {
  metadata {
    name = "mysql-pv-claim"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "3Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.mysql_pv.metadata[0].name
    storage_class_name = var.storageClassName
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 3306
      target_port = "3306"
    }

    selector = {
      app = "mysql"
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"

    labels = {
      app = "mysql"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        volume {
          name = "mysql-persistent-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql_pv_claim.metadata[0].name
          }
        }

        container {
          name  = "mysql"
          image = "mysql:5.7"
          args  = ["--ignore-db-dir=lost+found"]

          port {
            name           = "mysql"
            container_port = 3306
          }

          env {
            name = "MYSQL_ROOT_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql-rundeckuser.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name  = "MYSQL_DATABASE"
            value = "rundeckdb"
          }

          env {
            name  = "MYSQL_USER"
            value = "rundeck"
          }

          env {
            name = "MYSQL_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql-rundeckuser.metadata[0].name
                key  = "password"
              }
            }
          }

          volume_mount {
            name       = "mysql-persistent-storage"
            mount_path = "/var/lib/mysql"
          }
        }
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

