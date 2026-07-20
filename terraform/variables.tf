variable "cluster_name" {
  type        = string
  default     = "articles-hoi"
  description = "Minikube cluster Jetstream"
}

variable "kubernetes_version" {
  type        = string
  default     = "v1.30.0"
  description = "K8s version to run inside Minikube"
}

variable "minikube_driver" {
  type        = string
  default     = "docker"
  description = "Minikube driver: docker as we will be using docker to host the contsnairs"
}

variable "nodes" {
  type        = number
  default     = 4
  description = "Total number of Minikube nodes (1 control + N-1 workers). Cilium CNI (see cni variable) handles cross-node pod networking reliably on ARM."
}

variable "cni" {
  type        = string
  default     = "cilium"
  description = "CNI plugin. cilium is more reliable than the default kindnet on multi-node ARM Minikube (kindnet has known cross-node pod-to-pod routing issues on Apple Silicon)."
}

variable "cpus" {
  type    = number
  default = 4
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "install_argocd" {
  type    = bool
  default = true
}

variable "install_ingress" {
  type    = bool
  default = true
}

variable "install_monitoring" {
  type        = bool
  default     = true
  description = "Install Prometheus & Grafana via kube-prometheus-stack helm chart"
}
