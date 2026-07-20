terraform {
  required_version = ">= 1.6.0"
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "~> 0.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "minikube" {
  kubernetes_version = var.kubernetes_version
}

provider "kubernetes" {
  host                   = minikube_cluster.articles-hoi.host
  client_certificate     = minikube_cluster.articles-hoi.client_certificate
  client_key             = minikube_cluster.articles-hoi.client_key
  cluster_ca_certificate = minikube_cluster.articles-hoi.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = minikube_cluster.articles-hoi.host
    client_certificate     = minikube_cluster.articles-hoi.client_certificate
    client_key             = minikube_cluster.articles-hoi.client_key
    cluster_ca_certificate = minikube_cluster.articles-hoi.cluster_ca_certificate
  }
}
