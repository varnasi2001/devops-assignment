output "cluster_name" {
  value = minikube_cluster.articles-hoi.cluster_name
}

output "kube_host" {
  value       = minikube_cluster.articles-hoi.host
  description = "Kube API server endpoint"
  sensitive   = true
}

output "kubectl_context_hint" {
  value = "kubectl config use-context ${minikube_cluster.articles-hoi.cluster_name}"
}

output "ingress_urls" {
  value = var.install_ingress ? join("\n    ", [
    "http://articles.local        (add '127.0.0.1 articles.local' to /etc/hosts, then run: minikube tunnel)",
    "http://argocd.local          (ArgoCD UI — admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)",
    "http://grafana.local         (Grafana — admin/admin)",
    "http://prometheus.local      (Prometheus UI)",
  ]) : "ingress disabled"
}

output "next_steps" {
  value = <<-EOT
    1. Build backend image:      cd ../backend && docker build -t articles-api:v1 .
    2. Load into minikube:        minikube image load articles-api:v1 --profile ${minikube_cluster.articles-hoi.cluster_name}
    3. Install MongoDB chart:     helm upgrade --install mongodb ../helm/mongodb -n mongodb --create-namespace
    4. Install backend chart:     helm upgrade --install articles ../helm/backend -n articles --create-namespace
    5. Or use ArgoCD:             kubectl apply -f ../argocd/master-argo-app.yaml
    6. Expose ingress (macOS/Linux): minikube tunnel --profile ${minikube_cluster.articles-hoi.cluster_name}
  EOT
}
