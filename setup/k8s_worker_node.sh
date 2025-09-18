// ...existing code...
#!/usr/bin/env bash
# Automated Kubernetes worker node setup for production (kubelet,kubeadm,kubectl,CRI-O)
# Supports Ubuntu 22.04 and 24.04. Run as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Configuration (edit if needed)
K8S_VERSION_SHORT="${K8S_VERSION_SHORT:-1.34.1}"
K8S_VERSION="${K8S_VERSION_SHORT}-00"
CRIO_VERSION="${K8S_VERSION_SHORT%.*}"   # e.g. 1.34
USER_TO_CONFIGURE="${SUDO_USER:-$(whoami)}"
# Provide join command as first argument or via env JOIN_COMMAND
JOIN_COMMAND="${1:-${JOIN_COMMAND:-}}"

log() { echo -e "\n==== $* ===="; }

if [[ $EUID -ne 0 ]]; then
  echo "Must run as root. Use sudo."
  exit 1
fi

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

# Install CRI-O
log "Adding CRI-O repository (version ${CRIO_VERSION})"
CRIO_REPO_KEY_URL="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${CRIO_VERSION}/${OS}/Release.key"
CRIO_REPO_URL="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${CRIO_VERSION}/${OS}/"

mkdir -p /usr/share/keyrings
curl -fsSL "${CRIO_REPO_KEY_URL}" | gpg --dearmor -o /usr/share/keyrings/crio-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/crio-archive-keyring.gpg] ${CRIO_REPO_URL} ./" > /etc/apt/sources.list.d/crio.list

log "Installing CRI-O and runtime"
apt-get update
apt-get install -y cri-o cri-o-runc

log "Ensure CRI-O cgroup manager is systemd if config exists"
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

# Install Kubernetes components
log "Adding Kubernetes apt repository (signed-by keyring)"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update
log "Install kubelet kubeadm kubectl (pinned to ${K8S_VERSION})"
apt-get install -y kubelet="${K8S_VERSION}" kubeadm="${K8S_VERSION}" kubectl="${K8S_VERSION}"
apt-mark hold kubelet kubeadm kubectl

log "Configure kubelet to prefer systemd cgroup driver and CRI-O socket"
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

# Check if node is already joined
if [[ -f /etc/kubernetes/kubelet.conf ]]; then
  log "This node already appears to be part of a cluster (/etc/kubernetes/kubelet.conf exists). Exiting."
  exit 0
fi

# Join cluster
if [[ -z "${JOIN_COMMAND}" ]]; then
  echo "No join command provided."
  echo "Provide join command as first argument or set JOIN_COMMAND env var."
  echo "Example: sudo ./k8s_worker_node.sh \"kubeadm join 10.0.0.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>\""
  exit 1
fi

# Ensure CRI socket option present in join command
if ! echo "${JOIN_COMMAND}" | grep -q -- '--cri-socket'; then
  JOIN_COMMAND="${JOIN_COMMAND} --cri-socket unix:///var/run/crio/crio.sock"
fi

log "Running kubeadm join"
# shellcheck disable=SC2086
bash -c "${JOIN_COMMAND}"

log "Post-join: ensure kubelet running"
systemctl restart kubelet
sleep 3
if systemctl is-active --quiet kubelet; then
  echo "kubelet active"
else
  journalctl -u kubelet -n 100 --no-pager
  exit 1
fi

log "Worker setup complete. Verify from control-plane: kubectl get nodes"
# ...existing code...