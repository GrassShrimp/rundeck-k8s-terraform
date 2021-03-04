resource "kubernetes_persistent_volume" "minio_pv" {
  metadata {
    name = "minio-pv"
  }

  spec {
    capacity = {
      storage = "5Gi"
    }

    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/kubernetes/minio-data"
      } 
    }

    storage_class_name = var.storageClassName
  }  
}

resource "kubernetes_persistent_volume_claim" "minio_pv_claim" {
  metadata {
    name = "minio-pv-claim"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.minio_pv.metadata[0].name
    storage_class_name = var.storageClassName
  }
}

resource "kubernetes_deployment" "minio_deployment" {
  metadata {
    name = "minio-deployment"

    labels = {
      app = "minio"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        volume {
          name = "storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio_pv_claim.metadata[0].name
          }
        }

        container {
          name  = "minio"
          image = "minio/minio:latest"
          args  = ["server", "/data"]

          port {
            host_port      = 9000
            container_port = 9000
          }

          env {
            name = "MINIO_ACCESS_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-log-storage.metadata[0].name
                key  = "awskey"
              }
            }
          }

          env {
            name = "MINIO_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-log-storage.metadata[0].name
                key  = "awssecret"
              }
            }
          }

          volume_mount {
            name       = "storage"
            mount_path = "/data"
          }
        }
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_service" "minio" {
  metadata {
    name = "minio"
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 9000
      target_port = "9000"
    }

    selector = {
      app = "minio"
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_job" "minio_create_bucket" {
  depends_on = [ kubernetes_deployment.minio_deployment ]
  metadata {
    name = "minio-create-bucket"
  }

  spec {
    completions = 1

    template {
      metadata {
        name = "minio-create-bucket"
      }

      spec {
        container {
          name    = "minio-bucket"
          image   = "minio/mc"
          command = ["/bin/sh", "-c", "sleep 30 && mc config host add miniorundeck $MINIO_URL $MINIO_ACCESS_KEY $MINIO_SECRET_KEY  && mc mb miniorundeck/$MINIO_BUCKET --ignore-existing"]

          env {
            name  = "MINIO_URL"
            value = "http://${kubernetes_service.minio.metadata[0].name}.default.svc.cluster.local:9000"
          }

          env {
            name = "MINIO_ACCESS_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-log-storage.metadata[0].name
                key  = "awskey"
              }
            }
          }

          env {
            name = "MINIO_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-log-storage.metadata[0].name
                key  = "awssecret"
              }
            }
          }

          env {
            name  = "MINIO_BUCKET"
            value = "rundeck"
          }
        }

        restart_policy = "Never"
      }
    }
  }
}

