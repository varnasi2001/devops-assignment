resource "minikube_cluster" "articles-hoi" {
  driver             = var.minikube_driver
  cluster_name       = var.cluster_name
  nodes              = var.nodes
  cpus               = var.cpus
  memory             = var.memory_mb
  kubernetes_version = var.kubernetes_version
  cni                = var.cni
  addons = [
    "default-storageclass",
    "storage-provisioner",
    "metrics-server",
    "volumesnapshots",     # dependency of csi-hostpath-driver
    "csi-hostpath-driver", # multi-node-aware PV provisioner (fixes hostpath-across-nodes bug)
  ]
}

# Make csi-hostpath-sc the default storage class instead of the (broken across
# multi-node) hostpath "standard". Terraform's kubernetes provider has no direct
# resource for switching the default SC, so this local-exec does it once after
# the cluster is up.
resource "null_resource" "default_storage_class" {
  triggers = {
    cluster_id = minikube_cluster.articles-hoi.id
  }
  provisioner "local-exec" {
    command = <<-EOT
      kubectl annotate storageclass standard        storageclass.kubernetes.io/is-default-class-      --overwrite || true
      kubectl annotate storageclass csi-hostpath-sc storageclass.kubernetes.io/is-default-class=true  --overwrite || true
    EOT
  }
  depends_on = [minikube_cluster.articles-hoi]
}

resource "null_resource" "helm_charts_deploy" {
  triggers = {
    argocd     = filesha256("${path.module}/../helm-templates/argo-cd-9.5.21/Chart.yaml")
    ingress    = filesha256("${path.module}/../helm-templates/ingress-nginx-4.11.2/Chart.yaml")
    monitoring = filesha256("${path.module}/../helm-templates/kube-prometheus-stack-62.6.0/Chart.yaml")
  }
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      for d in "${path.module}/../helm-templates/argo-cd-9.5.21" \
               "${path.module}/../helm-templates/ingress-nginx-4.11.2" \
               "${path.module}/../helm-templates/kube-prometheus-stack-62.6.0"; do
        helm dependency update "$d"
      done
    EOT
  }
}

resource "kubernetes_namespace" "ingress" {
  count      = var.install_ingress ? 1 : 0
  metadata { name = "ingress-nginx" }
  depends_on = [minikube_cluster.articles-hoi]
}

resource "helm_release" "ingress_nginx" {
  count             = var.install_ingress ? 1 : 0
  name              = "ingress-nginx"
  namespace         = kubernetes_namespace.ingress[0].metadata[0].name
  chart             = "${path.module}/../helm-templates/ingress-nginx-4.11.2"
  values            = [file("${path.module}/../helm-overrides/ingress-nginx/custom-values.yaml")]
  dependency_update = true
  timeout           = 300
  depends_on        = [null_resource.helm_charts_deploy]
}

resource "kubernetes_namespace" "argocd" {
  count      = var.install_argocd ? 1 : 0
  metadata { name = "argocd" }
  depends_on = [minikube_cluster.articles-hoi]
}

resource "helm_release" "argocd" {
  count             = var.install_argocd ? 1 : 0
  name              = "argocd"
  namespace         = kubernetes_namespace.argocd[0].metadata[0].name
  chart             = "${path.module}/../helm-templates/argo-cd-9.5.21"
  values            = [file("${path.module}/../helm-overrides/argo-cd/custom-values.yaml")]
  dependency_update = true
  timeout           = 600
  depends_on        = [helm_release.ingress_nginx, null_resource.helm_charts_deploy]
}

resource "kubernetes_namespace" "monitoring" {
  count      = var.install_monitoring ? 1 : 0
  metadata { name = "monitoring" }
  depends_on = [minikube_cluster.articles-hoi]
}

resource "helm_release" "monitoring" {
  count             = var.install_monitoring ? 1 : 0
  name              = "kps"
  namespace         = kubernetes_namespace.monitoring[0].metadata[0].name
  chart             = "${path.module}/../helm-templates/kube-prometheus-stack-62.6.0"
  values            = [file("${path.module}/../helm-overrides/kube-prometheus-stack/custom-values.yaml")]
  dependency_update = true
  timeout           = 900
  depends_on        = [helm_release.ingress_nginx, null_resource.helm_charts_deploy]
}
