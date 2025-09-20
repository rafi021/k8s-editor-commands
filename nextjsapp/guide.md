# Deploy Next.js to Kubernetes on WSL (Windows + Ubuntu) with NGINX Ingress

This guide walks you through creating a Next.js app, containerizing it with Docker, deploying it to a Kubernetes cluster running in WSL Ubuntu, and exposing it via NGINX Ingress so you can access it from your Windows browser.

You’ll run Linux-side commands in WSL Ubuntu, and a couple of steps on Windows (hosts file update). Adjust names and versions as you prefer.

---

## Prerequisites

- Windows 10/11 with WSL2 and an Ubuntu distro installed
- Kubernetes running in WSL (k3s, k8s, or kind). If you’re using k3s, ensure `kubectl` points to it.
- Docker available inside WSL (Docker Desktop with WSL integration or native Docker in WSL)
- Node.js 18+ and npm in WSL (for local build/testing)
- Helm 3 (for installing ingress-nginx)

Verify basics in WSL Ubuntu:

```bash
kubectl version --client
kubectl get nodes
docker version
node -v
npm -v
helm version
```

If Docker Desktop is installed on Windows, enable its WSL integration (Settings > Resources > WSL Integration) for your Ubuntu distro.

---

## 1) Create a Next.js Project

In WSL Ubuntu:

```bash
cd ~
npx create-next-app@latest nextjs-k8s \
  --typescript \
  --eslint \
  --app \
  --src-dir \
  --use-npm

cd nextjs-k8s
```

Optional: start the dev server locally to sanity check.

```bash
npm run dev
# Visit http://localhost:3000 from a WSL browser or Windows browser if port is forwarded by your setup.
```

Add a minimal `next.config.js` to enable standalone output for smaller Docker images:

```bash
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone'
};
module.exports = nextConfig;
EOF
```

---

## 2) Containerize with Docker

Add a `.dockerignore`:

```bash
cat > .dockerignore << 'EOF'
node_modules
.next/cache
npm-debug.log
.git
.vscode
Dockerfile*
.dockerignore
EOF
```

Create a multi-stage `Dockerfile` optimized for Next.js standalone output:

```bash
cat > Dockerfile << 'EOF'
# 1) Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm install --only=production

# Copy rest of the source and build
COPY . .
RUN npm run build

# 2) Runtime stage
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
# Ensure the app listens on port 3000 by default
ENV PORT=3000

# Copy only what we need from the build
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
EOF
```

Build and test locally (optional):

```bash
docker build -t nextjs-k8s:local .
docker run --rm -p 3000:3000 nextjs-k8s:local
# Visit http://localhost:3000
```

Push to a registry (recommended for k8s):

```bash
# Use your Docker Hub username
export DOCKER_USER="<your-dockerhub-username>"
export IMAGE_TAG="v1"
docker tag nextjs-k8s:local $DOCKER_USER/nextjs-k8s:$IMAGE_TAG
docker login
docker push $DOCKER_USER/nextjs-k8s:$IMAGE_TAG
```

Notes for k3s/containerd without external registry:

- Option A (preferred): Push to Docker Hub (above) or a private registry.
- Option B: Import image directly into k3s (containerd):

  ```bash
  # Save and import image into containerd (k3s)
  docker save nextjs-k8s:local | sudo k3s ctr images import -
  # Then use image name `nextjs-k8s:local` in the Deployment spec
  ```

---

## 3) Kubernetes Manifests (Namespace, Deployment, Service)

Create a working directory for k8s files:

```bash
mkdir -p k8s
cd k8s
```

Namespace:

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: web
```

Deployment (uses image from Docker Hub by default; adapt if you imported locally):

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextjs-app
  namespace: web
  labels:
    app: nextjs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nextjs-app
  template:
    metadata:
      labels:
        app: nextjs-app
    spec:
      containers:
        - name: nextjs
          image: <your-dockerhub-username>/nextjs-k8s:v1 # or nextjs-k8s:local if imported to k3s
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 3000
          env:
            - name: PORT
              value: "3000"
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

Service (ClusterIP):

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nextjs-svc
  namespace: web
spec:
  selector:
    app: nextjs-app
  ports:
    - name: http
      port: 80
      targetPort: 3000
  type: ClusterIP
```

Apply:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

kubectl -n web rollout status deploy/nextjs-app
kubectl -n web get pods -o wide
kubectl -n web get svc nextjs-svc
```

---

## 4) Install NGINX Ingress Controller (for WSL)

In bare-metal/WSL environments, use NodePort or hostNetwork so Windows can reach the controller. Here we’ll use NodePort for clarity.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

kubectl create namespace ingress-nginx || true

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx \
  --set controller.watchIngressWithoutClass=true \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

kubectl -n ingress-nginx get pods -o wide
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

If you prefer hostNetwork (binds directly to the node’s IP on ports 80/443), you can install with:

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.hostNetwork=true \
  --set controller.kind=DaemonSet \
  --set dnsPolicy=ClusterFirstWithHostNet \
  --set controller.daemonset.useHostPort=true \
  --set controller.containerPort.http=80 \
  --set controller.containerPort.https=443
```

Note: hostNetwork requires the ports 80/443 not be used by other processes in WSL.

---

## 5) Create Ingress Resource

Create an Ingress to route `nextjs.local` to the service. Adjust host as desired.

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nextjs-ingress
  namespace: web
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: nextjs.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nextjs-svc
                port:
                  number: 80
```

Apply and verify:

```bash
kubectl apply -f k8s/ingress.yaml
kubectl -n web describe ingress nextjs-ingress
```

---

## 6) Make It Reachable from Windows Browser

Determine the WSL Ubuntu IP address (from WSL):

```bash
ip -brief address show eth0 | awk '{print $3}' | cut -d/ -f1
# or
hostname -I | awk '{print $1}'
```

Depending on how you installed ingress-nginx:

- If using NodePort (from section 4), HTTP is on port `30080` of the WSL IP.
- If using hostNetwork, HTTP is on port `80` of the WSL IP.

Update Windows hosts file to resolve `nextjs.local` to your WSL IP:

1) Open an elevated PowerShell or Command Prompt (Run as Administrator)

2) Edit hosts file:

```
notepad C:\Windows\System32\drivers\etc\hosts
```

3) Add a line (replace 172.22.113.249 with your WSL IP):

```
172.22.113.249   nextjs.local
```

4) Save the file.

Now browse from Windows:

- If NodePort: `http://nextjs.local:30080`
- If hostNetwork: `http://nextjs.local`

You should see your Next.js app.

Tip: You can also use an on-the-fly DNS like nip.io without editing hosts, e.g. set host to `nextjs.<WSL-IP>.nip.io` in the Ingress, then browse directly.

---

## 7) Validate and Troubleshoot

From WSL:

```bash
kubectl -n web get pods -o wide
kubectl -n web logs -l app=nextjs-app --tail=100
kubectl -n web describe deploy nextjs-app
kubectl -n web describe svc nextjs-svc
kubectl -n web describe ingress nextjs-ingress
kubectl -n ingress-nginx get pods -o wide
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200
```

Test HTTP path routing inside WSL:

```bash
# NodePort path (replace IP)
curl -I http://<WSL-IP>:30080/

# hostNetwork path
curl -I http://<WSL-IP>/
```

Common issues:

- Pods CrashLoopBackOff: Check `kubectl logs`, verify Node version and Dockerfile.
- ImagePullBackOff: Ensure the image name/tag is correct and pushed, or import into k3s.
- Ingress 404: Verify host header matches (use `curl -H "Host: nextjs.local" http://<WSL-IP>:30080/`).
- Windows can’t reach WSL IP: Recheck WSL IP, firewall settings, and that NodePort or hostNetwork is used.

---

## 8) Optional: CI-friendly Image Tagging and Rollouts

Use unique tags per build and roll out:

```bash
export IMAGE_TAG="v$(date +%Y%m%d%H%M%S)"
docker build -t $DOCKER_USER/nextjs-k8s:$IMAGE_TAG .
docker push $DOCKER_USER/nextjs-k8s:$IMAGE_TAG

kubectl -n web set image deploy/nextjs-app nextjs=$DOCKER_USER/nextjs-k8s:$IMAGE_TAG
kubectl -n web rollout status deploy/nextjs-app
```

---

## 9) Cleanup

```bash
kubectl delete -f k8s/ingress.yaml
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/namespace.yaml

helm -n ingress-nginx uninstall ingress-nginx || true
kubectl delete namespace ingress-nginx || true
```

---

## File Map Recap

- `nextjs-k8s/`
  - `next.config.js`
  - `.dockerignore`
  - `Dockerfile`
  - `k8s/namespace.yaml`
  - `k8s/deployment.yaml`
  - `k8s/service.yaml`
  - `k8s/ingress.yaml`

You now have a reproducible setup to build, deploy, and expose a Next.js app on a Kubernetes cluster in WSL Ubuntu, accessible from your Windows browser via NGINX Ingress.
