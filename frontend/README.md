# Next.js 15 Kubernetes Deployment

This repository contains Kubernetes manifests to deploy a Next.js 15 application with nginx as a reverse proxy.

## Architecture

```
Browser → nginx (Port 30080) → Next.js App (Port 3000)
```

## Files Overview

- `frontend-deployment.yaml` - Next.js application deployment
- `frontend-service.yaml` - ClusterIP service for Next.js app
- `nginx-configmap.yaml` - nginx configuration with reverse proxy settings
- `nginx-deployment.yaml` - nginx proxy deployment
- `nginx-service.yaml` - NodePort service exposing nginx on port 30080
- `deploy-nextjs.sh` - Deployment script

## Prerequisites

1. **Kubernetes cluster** running (k3s, minikube, etc.)
2. **kubectl** configured to connect to your cluster
3. **Docker image** of your Next.js 15 application

## Before Deployment

### 1. Build and Push Your Next.js Docker Image

Create a `Dockerfile` for your Next.js app if you haven't already:

```dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the application
RUN yarn build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

Build and tag your image:
```bash
docker build -t your-nextjs-app:latest .
```

### 2. Update Image Reference

Edit `frontend-deployment.yaml` and replace `your-nextjs-app:latest` with your actual image name:

```yaml
containers:
- name: nextjs-app
  image: your-nextjs-app:latest  # Replace this
```

## Deployment

### Option 1: Use the Deployment Script (Recommended)

```bash
chmod +x deploy-nextjs.sh
./deploy-nextjs.sh
```

### Option 2: Manual Deployment

Deploy resources in order:

```bash
# 1. Create nginx configuration
kubectl apply -f nginx-configmap.yaml

# 2. Deploy Next.js application
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# 3. Deploy nginx proxy
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
```

## Accessing Your Application

After deployment, your application will be accessible at:
- `http://localhost:30080` (if running locally)
- `http://<node-ip>:30080` (for remote clusters)

To find your node IP:
```bash
kubectl get nodes -o wide
```

## Monitoring

### Check Deployment Status
```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

### View Logs
```bash
# Next.js application logs
kubectl logs -l app=nextjs-frontend

# Nginx logs
kubectl logs -l app=nginx-proxy
```

### Debug Services
```bash
kubectl describe service nextjs-frontend-service
kubectl describe service nginx-proxy-service
```

## Configuration

### nginx Configuration

The nginx configuration includes:
- **Reverse proxy** to Next.js application
- **Static file caching** for optimal performance
- **Gzip compression** for reduced bandwidth
- **Security headers** for enhanced security
- **Rate limiting** for API endpoints
- **Health check endpoint** at `/health`

### Resource Limits

**Next.js Application:**
- Requests: 256Mi memory, 250m CPU
- Limits: 512Mi memory, 500m CPU

**nginx Proxy:**
- Requests: 64Mi memory, 100m CPU
- Limits: 128Mi memory, 200m CPU

## Scaling

Scale your deployments as needed:

```bash
# Scale Next.js application
kubectl scale deployment nextjs-frontend --replicas=5

# Scale nginx proxy
kubectl scale deployment nginx-proxy --replicas=3
```

## Cleanup

To remove all resources:

```bash
kubectl delete -f nginx-service.yaml
kubectl delete -f nginx-deployment.yaml
kubectl delete -f nginx-configmap.yaml
kubectl delete -f frontend-service.yaml
kubectl delete -f frontend-deployment.yaml
```

## Troubleshooting

### Common Issues

1. **Pods not starting:** Check image availability and resource limits
2. **Service not accessible:** Verify NodePort and firewall settings
3. **nginx 502 errors:** Check if Next.js service is running and accessible

### Debug Commands

```bash
# Check pod status
kubectl get pods -o wide

# View pod logs
kubectl logs <pod-name>

# Execute into pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forward for testing
kubectl port-forward svc/nextjs-frontend-service 3000:3000
kubectl port-forward svc/nginx-proxy-service 8080:80
```

## Next Steps

1. Configure **Ingress** for domain-based routing
2. Add **TLS/SSL certificates** for HTTPS
3. Implement **horizontal pod autoscaling**
4. Set up **monitoring and alerting**
5. Configure **persistent volumes** if needed