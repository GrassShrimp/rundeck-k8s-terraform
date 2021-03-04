resource "kubernetes_ingress" "rudeckpro_nginx" {
  metadata {
    name = "rudeckpro-nginx"

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"

      "nginx.ingress.kubernetes.io/affinity" = "cookie"

      "nginx.ingress.kubernetes.io/session-cookie-expires" = "172800"

      "nginx.ingress.kubernetes.io/session-cookie-max-age" = "172800"

      "nginx.ingress.kubernetes.io/session-cookie-name" = "route"
    }
  }

  spec {
    rule {
      host = "localhost"

      http {
        path {
          path = "/"

          backend {
            service_name = "rundeckpro"
            service_port = "8080"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rundeckpro" {
  metadata {
    name = "rundeckpro"
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 8080
      target_port = "4440"
    }

    selector = {
      app = "rundeckpro"
    }

    type                    = "LoadBalancer"
    session_affinity        = "ClientIP"
    external_traffic_policy = "Local"
  }
}

resource "kubernetes_deployment" "rundeckpro" {
  metadata {
    name      = "rundeckpro"
    namespace = "default"

    labels = {
      app = "rundeckpro"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "rundeckpro"
      }
    }

    template {
      metadata {
        labels = {
          app = "rundeckpro"
        }
      }

      spec {
        volume {
          name = "license"

          secret {
            secret_name = kubernetes_secret.rundeckpro-license.metadata[0].name

            items {
              key  = "rundeckpro-license.key"
              path = "rundeckpro-license.key"
            }
          }
        }

        volume {
          name = "acl"

          secret {
            secret_name = kubernetes_secret.rundeckpro-admin-acl.metadata[0].name

            items {
              key  = "admin-role.aclpolicy"
              path = "admin-role.aclpolicy"
            }
          }
        }

        volume {
          name = "kubeconfig"

          secret {
            secret_name = kubernetes_secret.kubeconfig.metadata[0].name

            items {
              key  = "config"
              path = "config"
            }
          }
        }

        container {
          name  = "rundeck"
          image = "rundeckpro/enterprise:SNAPSHOT"

          port {
            container_port = 4440
          }

          env {
            name  = "RUNDECK_GRAILS_URL"
            value = "http://localhost"
          }

          env {
            name  = "RUNDECK_DATABASE_DRIVER"
            value = "org.mariadb.jdbc.Driver"
          }

          env {
            name  = "RUNDECK_DATABASE_URL"
            value = "jdbc:mysql://${kubernetes_service.mysql.metadata[0].name}.default.svc.cluster.local:3306/rundeckdb?autoReconnect=true&useSSL=false"
          }

          env {
            name  = "RUNDECK_DATABASE_USERNAME"
            value = "rundeck"
          }

          env {
            name = "RUNDECK_DATABASE_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql-rundeckuser.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name  = "RUNDECK_PLUGIN_EXECUTIONFILESTORAGE_NAME"
            value = "com.rundeck.rundeckpro.amazon-s3"
          }

          env {
            name  = "RUNDECK_PLUGIN_EXECUTIONFILESTORAGE_S3_BUCKET"
            value = "rundeck"
          }

          env {
            name  = "RUNDECK_PLUGIN_EXECUTIONFILESTORAGE_S3_REGION"
            value = "us-east-2"
          }

          env {
            name  = "RUNDECK_PLUGIN_EXECUTIONFILESTORAGE_S3_ENDPOINT"
            value = "http://${kubernetes_service.minio.metadata[0].name}.default.svc.cluster.local:9000"
          }

          env {
            name  = "RUNDECK_PLUGIN_EXECUTIONFILESTORAGE_S3_PATHSTYLE"
            value = "true"
          }

          env {
            name = "AWS_ACCESS_KEY_ID"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-log-storage.metadata[0].name
                key  = "awskey"
              }
            }
          }

          env {
            name = "AWS_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-log-storage.metadata[0].name
                key  = "awssecret"
              }
            }
          }

          env {
            name  = "RUNDECK_PLUGIN_CLUSTER_HEARTBEAT_CONSIDERDEAD"
            value = "120"
          }

          env {
            name  = "RUNDECK_PLUGIN_CLUSTER_AUTOTAKEOVER_SLEEP"
            value = "10"
          }

          env {
            name = "RUNDECK_STORAGE_CONVERTER_1_CONFIG_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-storage-converter.metadata[0].name
                key  = "masterpassword"
              }
            }
          }

          env {
            name = "RUNDECK_CONFIG_STORAGE_CONVERTER_1_CONFIG_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret.rundeckpro-storage-converter.metadata[0].name
                key  = "masterpassword"
              }
            }
          }

          env {
            name  = "RUNDECK_PLUGIN_CLUSTER_REMOTEEXECUTION_ENABLED"
            value = "false"
          }

          volume_mount {
            name       = "license"
            mount_path = "/home/rundeck/etc/rundeckpro-license.key"
            sub_path   = "rundeckpro-license.key"
          }

          volume_mount {
            name       = "acl"
            mount_path = "/home/rundeck/etc/admin-role.aclpolicy"
            sub_path   = "admin-role.aclpolicy"
          }

          volume_mount {
            name       = "kubeconfig"
            mount_path = "/home/rundeck/.kube/config"
            sub_path   = "config"
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = "4440"
              scheme = "HTTP"
            }

            initial_delay_seconds = 500
            period_seconds        = 120
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = "4440"
              scheme = "HTTP"
            }

            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }
}

