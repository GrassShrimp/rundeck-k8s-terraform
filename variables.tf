variable "awskey" {
  type = string
}

variable "awssecret" {
  type = string
}

variable "masterpassword" {
  type = string
}

variable "password" {
  type = string
}

variable "rundeckpro-license-path" {
  type = string
  default = "./data/rundeckpro-license.key"
}

variable "admin-role-aclpolicy-path" {
  type = string
  default = "./data/admin-role.aclpolicy"
}

variable "kubeconfig-path" {
  type = string
  default = "~/.kube/config"
}

variable "storageClassName" {
  type = string
}