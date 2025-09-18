#!/usr/bin/env bash
set -euo pipefail

# deploy-laravel.sh
# Automates deployment of Laravel + MySQL + Redis + Queue + HPA
# Usage examples:
#   ./deploy-laravel.sh --image your-registry/laravel:prod --app-key base64:XXXX --db-pass Secret123 --root-pass Root123
#   ./deploy-laravel.sh --reuse-secret
# Flags:
#   --namespace <ns>        Namespace to deploy into (default: default)
#   --image <image>         Laravel image (required if secret not reused)
#   --app-key <key>         Laravel APP_KEY (with base64: prefix)
#   --db-user <user>        DB username (default: laravel)
#   --db-pass <pass>        DB user password
#   --root-pass <pass>      MySQL root password
#   --skip-hpa              Skip applying HPA
#   --reuse-secret          Do not recreate laravel-secret
#   --wait                  Wait for deployments/statefulsets ready
#   --dry-run               Show kubectl commands only
#   --help                  Show help

NAMESPACE=default
IMAGE=""
APP_KEY=""
DB_USER="laravel"
DB_PASS=""
ROOT_PASS=""
APPLY_HPA=1
REUSE_SECRET=0
WAIT=0
DRY_RUN=0

log() { echo -e "[INFO] $*"; }
warn() { echo -e "[WARN] $*" >&2; }
err()  { echo -e "[ERROR] $*" >&2; exit 1; }

usage() { grep '^# ' "$0" | sed 's/^# //'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace) NAMESPACE=$2; shift 2;;
    --image) IMAGE=$2; shift 2;;
    --app-key) APP_KEY=$2; shift 2;;
    --db-user) DB_USER=$2; shift 2;;
    --db-pass) DB_PASS=$2; shift 2;;
    --root-pass) ROOT_PASS=$2; shift 2;;
    --skip-hpa) APPLY_HPA=0; shift;;
    --reuse-secret) REUSE_SECRET=1; shift;;
    --wait) WAIT=1; shift;;
    --dry-run) DRY_RUN=1; shift;;
    --help|-h) usage;;
    *) err "Unknown argument: $1";;
  esac
done

kubectl_cmd() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo kubectl -n "$NAMESPACE" "$@"
  else
    kubectl -n "$NAMESPACE" "$@"
  fi
}

# Validate
if [[ $REUSE_SECRET -eq 0 ]]; then
  [[ -z "$IMAGE" ]] && err "--image required when not reusing secret"
  [[ -z "$APP_KEY" ]] && err "--app-key required when not reusing secret"
  [[ -z "$DB_PASS" ]] && err "--db-pass required when not reusing secret"
  [[ -z "$ROOT_PASS" ]] && err "--root-pass required when not reusing secret"
fi

log "Namespace: $NAMESPACE"

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  log "Creating namespace $NAMESPACE"
  kubectl create namespace "$NAMESPACE"
fi

# Create / update ConfigMap & nginx config
log "Applying ConfigMaps"
kubectl_cmd apply -f laravel-configmap.yaml
kubectl_cmd apply -f laravel-nginx-config.yaml

# Secrets
if [[ $REUSE_SECRET -eq 0 ]]; then
  log "(Re)creating secret laravel-secret"
  APP_KEY_B64=$(printf "%s" "$APP_KEY" | base64 -w0)
  DB_USER_B64=$(printf "%s" "$DB_USER" | base64 -w0)
  DB_PASS_B64=$(printf "%s" "$DB_PASS" | base64 -w0)
  ROOT_PASS_B64=$(printf "%s" "$ROOT_PASS" | base64 -w0)
  cat > /tmp/laravel-secret-gen.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: laravel-secret
  labels:
    app: laravel
    component: secret
type: Opaque
data:
  APP_KEY: "$APP_KEY_B64"
  DB_USERNAME: "$DB_USER_B64"
  DB_PASSWORD: "$DB_PASS_B64"
  DB_ROOT_PASSWORD: "$ROOT_PASS_B64"
  REDIS_PASSWORD: ""
EOF
  kubectl_cmd apply -f /tmp/laravel-secret-gen.yaml
else
  log "Reusing existing secret laravel-secret"
fi

# Patch image in deployment manifests if provided
if [[ -n "$IMAGE" ]]; then
  log "Temporarily staging patched manifests with image: $IMAGE"
  TMPDIR=$(mktemp -d)
  cp laravel-deplyment.yaml "$TMPDIR/laravel-deplyment.yaml"
  cp laravel-queue-worker.yaml "$TMPDIR/laravel-queue-worker.yaml"
  sed -i "s|your-laravel-image:latest|$IMAGE|g" "$TMPDIR/laravel-deplyment.yaml" "$TMPDIR/laravel-queue-worker.yaml"
else
  TMPDIR="."
fi

# Core services
log "Applying MySQL & Redis"
kubectl_cmd apply -f mysql-statefulset.yaml
kubectl_cmd apply -f redis-deployment.yaml

# Laravel app + queue
log "Applying Laravel web & queue worker"
kubectl_cmd apply -f "$TMPDIR/laravel-deplyment.yaml"
kubectl_cmd apply -f "$TMPDIR/laravel-queue-worker.yaml"

# HPA optional
if [[ $APPLY_HPA -eq 1 ]]; then
  log "Applying HPA"
  kubectl_cmd apply -f laravel-hpa.yaml || warn "HPA apply failed (metrics server?)"
else
  log "Skipping HPA"
fi

if [[ $WAIT -eq 1 ]]; then
  log "Waiting for MySQL StatefulSet"
  kubectl_cmd rollout status statefulset/mysql --timeout=300s || warn "MySQL not ready in time"
  log "Waiting for Laravel web deployment"
  kubectl_cmd rollout status deployment/laravel-web --timeout=300s || warn "Laravel web not ready"
  log "Waiting for Queue worker deployment"
  kubectl_cmd rollout status deployment/laravel-queue-worker --timeout=300s || warn "Queue worker not ready"
fi

log "Summary (namespace: $NAMESPACE)"
kubectl_cmd get pods -l app=laravel
kubectl_cmd get svc
kubectl_cmd get hpa || true

log "Done. To expose externally, create an Ingress or NodePort service for laravel-web."
