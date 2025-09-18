#!/bin/bash

# Deploy Next.js Application to Kubernetes with Nginx Proxy
# This script deploys all components in the correct order

echo "🚀 Deploying Next.js 15 Application to Kubernetes..."

# Apply ConfigMap first (nginx configuration)
echo "📋 Creating nginx configuration..."
kubectl apply -f nginx-configmap.yaml

# Deploy Next.js application
echo "🏗️  Deploying Next.js frontend..."
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# Deploy nginx proxy
echo "🔧 Deploying nginx proxy..."
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nextjs-frontend
kubectl wait --for=condition=available --timeout=300s deployment/nginx-proxy

# Get service information
echo "📊 Deployment Status:"
kubectl get deployments
echo ""
kubectl get services
echo ""
kubectl get pods

# Get access information
NODE_PORT=$(kubectl get service nginx-proxy-service -o jsonpath='{.spec.ports[0].nodePort}')
echo ""
echo "🌐 Your Next.js application is now accessible at:"
echo "   http://localhost:$NODE_PORT"
echo "   http://<your-node-ip>:$NODE_PORT"
echo ""
echo "💡 To get your node IP, run: kubectl get nodes -o wide"