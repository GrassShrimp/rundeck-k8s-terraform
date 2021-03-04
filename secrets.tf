resource "kubernetes_secret" "rundeckpro-storage-converter" {
  metadata {
    name = "rundeckpro-storage-converter"
  }

  data = {
    "masterpassword" = var.masterpassword
  }

  type = "Opaque"
}

resource "kubernetes_secret" "rundeckpro-log-storage" {
  metadata {
    name = "rundeckpro-log-storage"
  }

  data = {
    "awskey" = var.awskey
    "awssecret" = var.awssecret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "mysql-rundeckuser" {
  metadata {
    name = "mysql-rundeckuser"
  }

  data = {
    "password" = var.password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "rundeckpro-license" {
  metadata {
    name = "rundeckpro-license"
  }

  data = {
    "rundeckpro-license.key" = file(var.rundeckpro-license-path)
  }

  type = "Opaque"
}

resource "kubernetes_secret" "rundeckpro-admin-acl" {
  metadata {
    name = "rundeckpro-admin-acl"
  }

  data = {
    "admin-role.aclpolicy" = file(var.admin-role-aclpolicy-path)
  }

  type = "Opaque"
}

resource "kubernetes_secret" "kubeconfig" {
  metadata {
    name = "kubeconfig"
  }

  data = {
    "config" = file(var.kubeconfig-path)
  }

  type = "Opaque"
}