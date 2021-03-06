# rundeck-k8s-terraform

install rundeck on k8s

## Prerequisites

- [terraform](https://www.terraform.io/downloads.html)
- [docker](https://www.docker.com/products/docker-desktop) and enable kubernetes

## Usage

check current context of kubernetes is __docker-desktop__

```bash
$ kubectl config current-context
```

initialize terraform module

```bash
$ terraform init
```

install rundeck

```bash
$ terraform apply -auto-approve
```

for destroy

```bash
$ terraform destroy -auto-approve
```

![rundeck](https://github.com/GrassShrimp/rundeck-k8s-terraform/blob/master/rundeck.png)