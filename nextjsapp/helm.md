# Deploy Next.js to Kubernetes using Helm (WSL Ubuntu + Windows)

This guide uses a Helm chart (in `nextjsapp/helm/nextjs`) to deploy a containerized Next.js app to a Kubernetes cluster running inside WSL Ubuntu, and exposes it via NGINX Ingress so you can access it from your Windows browser.

## Prerequisites
- WSL Ubuntu with `kubectl`, `helm`, and access to your Kubernetes cluster
- Docker in WSL (Docker Desktop with WSL integration or native Docker)
- A built and pushed image, e.g. `<your-dockerhub-username>/nextjs-k8s:v1`

If you don’t have the image yet, see `guide.md` at the repo root for Dockerfile and build steps.

## Chart Layout
```
nextjsapp/helm/nextjs/
	Chart.yaml
	values.yaml
	templates/
		deployment.yaml
		service.yaml
		ingress.yaml
		_helpers.tpl
		NOTES.txt
	.helmignore
```

## 1) Install NGINX Ingress Controller

Use NodePort (recommended for WSL), mapping 80->30080, 443->30443:

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

kubectl -n ingress-nginx get svc ingress-nginx-controller
```

Alternative (hostNetwork, binds to 80/443 directly): see `guide.md` for flags.

## 2) Configure Values

Edit `values.yaml` or override via `--set`:

```bash
cd ~/k3s/nextjsapp/helm
helm upgrade --install next-web ./nextjs \
	--namespace web \
	--create-namespace \
	--set image.repository=<your-dockerhub-username>/nextjs-k8s \
	--set image.tag=v1 \
	--set ingress.enabled=true \
	--set ingress.className=nginx \
	--set ingress.hosts[0].host=nextjs.local \
	--set replicaCount=2
```

This creates a Deployment, Service (ClusterIP), and Ingress pointing `nextjs.local` to the app on port 80.

Check resources:

```bash
kubectl -n web get deploy,svc,ingress,pods -l app.kubernetes.io/instance=next-web -o wide
```

## 3) Make It Reachable from Windows

Find your WSL IP:

```bash
hostname -I | awk '{print $1}'
```

If you used NodePort for ingress-nginx, HTTP is available on port `30080` of the WSL IP.

Add to Windows hosts file (Run Notepad as Administrator):

```
notepad C:\\Windows\\System32\\drivers\\etc\\hosts
```

Add line (replace 172.24.240.1):

```
172.24.240.1  nextjs.local
```

Browse from Windows:

- NodePort: http://nextjs.local:30080
- HostNetwork: http://nextjs.local

## 4) Rolling Updates

Build a new image tag and update only the image values:

```bash
helm upgrade --install next-web ./nextjs \
	--namespace web \
	--set image.repository=<your-dockerhub-username>/nextjs-k8s \
	--set image.tag=v2

kubectl -n web rollout status deploy/next-web-nextjs
```

Note: the deployment name is derived from release name and chart name; list it with:

```bash
kubectl -n web get deploy -l app.kubernetes.io/instance=next-web
```

## 5) Uninstall

```bash
helm -n web uninstall next-web
helm -n ingress-nginx uninstall ingress-nginx
kubectl delete namespace web || true
kubectl delete namespace ingress-nginx || true
```

## Troubleshooting
- `ImagePullBackOff`: verify `image.repository` and `image.tag`, ensure you pushed the image or imported it into k3s.
- `404 Not Found` from ingress: confirm host header matches (`curl -H "Host: nextjs.local" http://<WSL-IP>:30080/`) and Ingress class is `nginx`.
- Pods not ready: check logs: `kubectl -n web logs -l app.kubernetes.io/instance=next-web --tail=100`.

