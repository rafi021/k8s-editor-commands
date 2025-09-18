# Laravel Backend Kubernetes Deployment

This directory contains Kubernetes manifests to deploy a Laravel application with MySQL 8.0 and Redis.

## Components

| File | Purpose |
|------|---------|
| `laravel-configmap.yaml` | Non-sensitive environment variables |
| `laravel-secret.yaml` | Sensitive values (APP_KEY, DB creds) |
| `mysql-statefulset.yaml` | MySQL 8.0 StatefulSet + headless Service + PVC |
| `redis-deployment.yaml` | Redis deployment + Service |
| `laravel-deplyment.yaml` | Laravel web Deployment (php-fpm + nginx sidecar) + Service |
| `laravel-queue-worker.yaml` | Queue worker Deployment (redis queue) |
| `laravel-hpa.yaml` | Horizontal Pod Autoscaler for web tier (optional) |

## Prerequisites

1. Build a production Laravel image that includes vendor dependencies, compiled assets, and correct permissions.
2. Create a valid Laravel `APP_KEY` (e.g. `php artisan key:generate --show`).
3. Base64 encode sensitive values for the Secret.
4. Ensure metrics server is installed if using the HPA.

## Example Dockerfile (php-fpm + nginx separate in pod)
```dockerfile
FROM php:8.2-fpm-alpine AS base

# System deps
RUN apk add --no-cache bash git curl libpng-dev libjpeg-turbo-dev freetype-dev oniguruma-dev icu-dev libzip-dev zip unzip

# PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd intl pdo pdo_mysql mbstring zip opcache

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

COPY . .
RUN composer dump-autoload --optimize && php artisan config:cache && php artisan route:cache

# Permissions
RUN chown -R www-data:www-data storage bootstrap/cache

USER www-data
EXPOSE 9000
CMD ["php-fpm"]
```

## Nginx ConfigMap (already embedded inline)
If you prefer a standalone file, create `laravel-nginx-config.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: laravel-nginx-config
  labels:
    app: laravel
    component: web

data:
  default.conf: |
    server {
      listen 8080;
      root /var/www/html/public;
      index index.php index.html;
      location /healthz { return 200 'ok'; }
      location / { try_files $uri $uri/ /index.php?$query_string; }
      location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
      }
      location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg)$ {
        expires 7d;
        access_log off;
      }
    }
```
Apply it before the deployment if not already present.

## Secrets
Update `laravel-secret.yaml` with real base64 values:
```bash
echo -n 'base64:XXXXXXXX' | base64  # APP_KEY including prefix
```

## Deployment Order
```bash
kubectl apply -f laravel-configmap.yaml
kubectl apply -f laravel-secret.yaml
kubectl apply -f mysql-statefulset.yaml
kubectl apply -f redis-deployment.yaml
# If using separate nginx config
kubectl apply -f laravel-nginx-config.yaml
kubectl apply -f laravel-deplyment.yaml
kubectl apply -f laravel-queue-worker.yaml
kubectl apply -f laravel-hpa.yaml   # optional
```

## Accessing the App
Currently the `laravel-web` Service is ClusterIP. To expose externally you can:
1. Create a NodePort service
2. or Use an Ingress (recommended)

### Example Ingress (if Ingress controller installed)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: laravel-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
    - host: laravel.local
      http:
        paths:
          - path: /(.*)
            pathType: Prefix
            backend:
              service:
                name: laravel-web
                port:
                  number: 80
```
Map `laravel.local` in `/etc/hosts` to your node IP for local testing.

## Queue Worker
The queue worker uses `php artisan queue:work`. Adjust args for Horizon if you use it.

## Scaling
```bash
kubectl scale deployment laravel-web --replicas=4
kubectl scale deployment laravel-queue-worker --replicas=2
```

## Backups
Set up external backup for MySQL PVC (Velero, snapshot, etc.). Redis is ephemeral here; use persistence or managed service in production.

## Troubleshooting
```bash
kubectl get pods -l app=laravel
kubectl logs deployment/laravel-web -c laravel
kubectl logs deployment/laravel-web -c nginx
kubectl logs deployment/laravel-queue-worker
kubectl describe pod <pod>
```

### Common Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| CrashLoopBackOff (mysql) | Bad root password | Update secret & delete pod |
| Migrations fail | DB not ready | Increase init wait or readiness probe |
| 502 via nginx sidecar | PHP-FPM not listening | Check container port, logs |
| Queue stuck | Redis unreachable | Check `redis` service/pod |

## Next Steps
- Add persistent storage for Redis if needed.
- Add TLS via Ingress + cert-manager.
- Add monitoring (Prometheus + Grafana + Laravel exporter).
- Configure centralized logging (ELK / Loki).
- Implement secrets management (Vault / external secrets).

## Automation Scripts

Two helper scripts are included to streamline deployment and teardown.

### deploy-laravel.sh
Automates applying ConfigMaps, Secrets, MySQL, Redis, Laravel web, queue worker, and optional HPA.

Usage examples:
```bash
./deploy-laravel.sh --image your-registry/laravel:prod \
  --app-key base64:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
  --db-pass StrongUserPass123 --root-pass StrongRootPass456 --wait
```

Flags:
- `--namespace <ns>`: Target namespace (default: default)
- `--image <image>`: Laravel image to inject (replaces placeholder)
- `--app-key <key>`: Laravel APP_KEY (include `base64:` prefix if generated that way)
- `--db-user <user>`: DB username (default: laravel)
- `--db-pass <pass>`: DB user password
- `--root-pass <pass>`: MySQL root password
- `--skip-hpa`: Do not apply HPA
- `--reuse-secret`: Reuse existing `laravel-secret` Secret instead of recreating
- `--wait`: Wait for rollouts to complete
- `--dry-run`: Print `kubectl` commands without executing

Dry run planning:
```bash
./deploy-laravel.sh --image repo/laravel:latest --app-key base64:XXX --db-pass p --root-pass r --dry-run
```

### destroy-laravel.sh
Safely tears down resources. PVC (MySQL data) retained unless `--wipe-data` used.

Examples:
```bash
./destroy-laravel.sh
./destroy-laravel.sh --namespace staging --wipe-data
```

Outputs remaining filtered resources for verification.

---
Maintained by: Platform Automation.
