#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLUSTER="${CLUSTER:-articles-hoi}"
REGISTRY="${REGISTRY:-}"
if [[ "$REGISTRY" == *"@"* ]]; then
  REGISTRY=""
fi
IMG_NAME="${IMG_NAME:-articles-api}"
IMG_TAG="${IMG_TAG:-v1}"
if [ -n "$REGISTRY" ]; then
  IMG="$REGISTRY/$IMG_NAME:$IMG_TAG"
else
  IMG="$IMG_NAME:$IMG_TAG"
  echo "WARNING: REGISTRY not set — image will only exist locally (minikube image load)."
  echo "         Set REGISTRY=<dockerhub-user> or REGISTRY=ghcr.io/<gh-user> to push properly."
fi
OV="$ROOT/helm-overrides"

echo ">>> terraform apply"
cd "$ROOT/terraform"
terraform init -upgrade
terraform apply -auto-approve

echo ">>> build backend image: $IMG"
cd "$ROOT/backend"
docker build -t "$IMG" .

if [ -n "$REGISTRY" ]; then
  echo ">>> push $IMG to registry"
  docker push "$IMG"
fi

echo ">>> loading image into Minikube"
minikube image load "$IMG" --profile "$CLUSTER"

echo ">>> install mongodb"
helm upgrade --install mongodb "$ROOT/helm-templates/mongodb" \
  -f "$OV/mongodb/custom-values.yaml" \
  -n mongodb --create-namespace --wait --timeout 5m

echo ">>> wait for mongo replica-set init job"
kubectl -n mongodb wait --for=condition=complete job/mongodb-init-rs --timeout=5m || true

echo ">>> copy mongo secret into articles namespace"
kubectl create namespace articles --dry-run=client -o yaml | kubectl apply -f -
kubectl -n mongodb get secret mongodb-root -o yaml \
  | sed 's/namespace: mongodb/namespace: articles/' \
  | kubectl apply -f -

echo ">>> install articles backend"
helm upgrade --install articles "$ROOT/helm-templates/articles-backend" \
  -f "$OV/articles-backend/custom-values.yaml" \
  --set "image.repository=${REGISTRY:+$REGISTRY/}$IMG_NAME" \
  --set "image.tag=$IMG_TAG" \
  -n articles --wait --timeout 5m

cat <<EOF

done.

add to /etc/hosts:
  127.0.0.1 articles.local argocd.local grafana.local prometheus.local

then in a second terminal:
  sudo minikube tunnel --profile $CLUSTER

test:
  ./scripts/test-api.sh

argocd admin password:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
EOF
