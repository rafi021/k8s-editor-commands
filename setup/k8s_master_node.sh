// ...existing code...
#!/usr/bin/env bash
# Automated Kubernetes master node setup for production (kubelet,kubeadm,kubectl,CRI-O)
# Supports Ubuntu 22.04 and 24.04. Run as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# === Configuration (edit if needed) ===
CRIO_VERSION=v1.33
K8S_VERSION_SHORT="1.34"
K8S_VERSION="${K8S_VERSION_SHORT}-00"
CRIO_VERSION="${CRIO_VERSION%.*}"   # e.g. 1.34
POD_NETWORK_CIDR="192.168.0.0/16"
USER_TO_CONFIGURE="${SUDO_USER:-$(whoami)}"
# Optionally set CONTROL_PLANE_ENDPOINT env var for HA/load-balancer DNS: e.g. export CONTROL_PLANE_ENDPOINT="lb.example.com:6443"
# ======================================

if [[ $EUID -ne 0 ]]; then
  echo "Must run as root. Use sudo."
  exit 1
fi

log() { echo -e "\n==== $* ===="; }

# Detect Ubuntu version and map to CRI-O repo name
. /etc/os-release
OS_VERSION_ID="${VERSION_ID:-}"
case "$OS_VERSION_ID" in
  "22.04"*) OS="xUbuntu_22.04";;
  "24.04"*) OS="xUbuntu_24.04";;
  *)
    echo "Unsupported Ubuntu version: ${OS_VERSION_ID}. Supported: 22.04, 24.04."
    exit 1
    ;;
esac

log "Basic package update and prerequisites"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

log "Disable swap and ensure it's off on reboot"
swapoff -a
sed -ri '/\sswap\s/s/^/#/' /etc/fstab || true

log "Enable kernel modules and sysctl params required by Kubernetes"
modprobe overlay || true
modprobe br_netfilter || true
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

cat > /etc/sysctl.d/99-k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# === Install CRI-O ===
log "Adding CRI-O repository (version ${CRIO_VERSION})"
CRIO_REPO_KEY_URL=" https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg"
CRIO_REPO_URL="https://download.opensuse.org/repositories/isv:/cri-o:/stable:/${CRIO_VERSION}/${OS}/"

mkdir -p /usr/share/keyrings
curl -fsSL "${CRIO_REPO_KEY_URL}" | gpg --dearmor -o /usr/share/keyrings/crio-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/crio-archive-keyring.gpg] ${CRIO_REPO_URL} ./" > /etc/apt/sources.list.d/crio.list

log "Installing CRI-O and runtime"
apt-get update
apt-get install -y cri-o cri-o-runc

log "Ensure CRI-O cgroup manager is systemd if configurable"
if grep -q 'cgroup_manager' /etc/crio/crio.conf 2>/dev/null; then
  sed -i 's/^cgroup_manager =.*/cgroup_manager = "systemd"/' /etc/crio/crio.conf || true
fi

systemctl daemon-reload
systemctl enable --now crio

log "Verify CRI-O is running"
if systemctl is-active --quiet crio; then
  echo "CRI-O running"
else
  journalctl -u crio --no-pager -n 50
  exit 1
fi

# === Install Kubernetes components ===
log "Adding Kubernetes apt repository (signed-by keyring)"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update
log "Install kubelet kubeadm kubectl (pinned to ${K8S_VERSION})"
apt-get install -y kubelet="${K8S_VERSION}" kubeadm="${K8S_VERSION}" kubectl="${K8S_VERSION}"
apt-mark hold kubelet kubeadm kubectl

log "Configure kubelet to prefer systemd cgroup driver"
cat > /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS=--cgroup-driver=systemd --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock
EOF

systemctl daemon-reload
systemctl enable --now kubelet

log "Waiting for kubelet to be active"
for i in {1..15}; do
  if systemctl is-active --quiet kubelet; then break; fi
  sleep 2
done
if ! systemctl is-active --quiet kubelet; then
  journalctl -u kubelet -n 100 --no-pager
  exit 1
fi

# === kubeadm init ===
if [ -f /etc/kubernetes/admin.conf ]; then
  log "kubeadm already initialized; skipping init"
else
  log "Initializing Kubernetes control plane with kubeadm"
  CONTROL_PLANE_ENDPOINT="${CONTROL_PLANE_ENDPOINT:-}"
  EXTRA_APISERVER_SAN=""
  if [ -n "$CONTROL_PLANE_ENDPOINT" ]; then
    EXTRA_APISERVER_SAN="--control-plane-endpoint ${CONTROL_PLANE_ENDPOINT}"
  fi

  kubeadm init \
    --kubernetes-version "v${K8S_VERSION_SHORT}" \
    --image-repository registry.k8s.io \
    --pod-network-cidr="${POD_NETWORK_CIDR}" \
    --cri-socket=/var/run/crio/crio.sock \
    ${EXTRA_APISERVER_SAN} \
    --upload-certs

  log "Setting up kubeconfig for user ${USER_TO_CONFIGURE}"
  mkdir -p /home/${USER_TO_CONFIGURE}/.kube
  cp -i /etc/kubernetes/admin.conf /home/${USER_TO_CONFIGURE}/.kube/config
  chown ${USER_TO_CONFIGURE}:${USER_TO_CONFIGURE} /home/${USER_TO_CONFIGURE}/.kube/config

  echo "Control-plane node remains tainted by default. To allow scheduling on master run as needed:"
  echo "  kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true"
fi

log "Installing Calico CNI (adjust if you use a different CNI)"
su - ${USER_TO_CONFIGURE} -c "kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico-standalone.yaml" || echo "Apply Calico manifest manually if this fails."

log "Final checks"
sysctl net.bridge.bridge-nf-call-iptables || true

log "Join command (for worker nodes):"
kubeadm token create --print-join-command || echo "Could not generate join command automatically. Run 'kubeadm token create --print-join-command' as root."

log "Setup complete. Run 'kubectl get nodes' and 'kubectl get pods -A' to verify."
# ...existing code...