#!/usr/bin/env bash
set -euo pipefail
# destroy-laravel.sh
# Tear down Laravel stack (keeps PVC by default unless --wipe-data)
# Usage: ./destroy-laravel.sh [--namespace default] [--wipe-data]

NAMESPACE=default
WIPE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace) NAMESPACE=$2; shift 2;;
    --wipe-data) WIPE=1; shift;;
    --help|-h) echo "Usage: $0 [--namespace <ns>] [--wipe-data]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }

log "Deleting Laravel resources in namespace $NAMESPACE"

kubectl -n "$NAMESPACE" delete deployment laravel-web --ignore-not-found
kubectl -n "$NAMESPACE" delete deployment laravel-queue-worker --ignore-not-found
kubectl -n "$NAMESPACE" delete deployment redis --ignore-not-found
kubectl -n "$NAMESPACE" delete statefulset mysql --ignore-not-found
kubectl -n "$NAMESPACE" delete service laravel-web redis mysql --ignore-not-found
kubectl -n "$NAMESPACE" delete hpa laravel-web-hpa --ignore-not-found
kubectl -n "$NAMESPACE" delete configmap laravel-config laravel-nginx-config --ignore-not-found
# Secret intentionally preserved unless wipe
if [[ $WIPE -eq 1 ]]; then
  kubectl -n "$NAMESPACE" delete secret laravel-secret --ignore-not-found
fi

if [[ $WIPE -eq 1 ]]; then
  log "Wiping MySQL PVCs"
  kubectl -n "$NAMESPACE" delete pvc -l app=mysql --ignore-not-found
else
  warn "PVCs retained. Use --wipe-data to remove persistent MySQL storage."
fi

log "Remaining resources (filtered):"
kubectl -n "$NAMESPACE" get all | grep -E 'laravel|mysql|redis' || true

log "Done."