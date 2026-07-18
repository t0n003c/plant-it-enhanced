# Kubernetes development deployment

These manifests run Plant-it Enhanced on Minikube for development and evaluation. For a single
UGREEN or other NAS, use the maintained Docker Compose examples at the repository root; they include
health checks, private database/cache networking, persistent uploads, and verified backup scripts.

## Prerequisites

- Minikube
- `kubectl`
- Helm, only when using the chart in `deployment/helm`

The server manifest uses `ghcr.io/t0n003c/plant-it-enhanced:latest`. Replace every placeholder in
`secret.yml` before applying it. Kubernetes Secrets are encoded transport objects, not a substitute
for an encrypted secret manager.

## Apply with kubectl

From `deployment/kubernetes`:

```bash
minikube start --driver=docker --mount --mount-string="/tmp/plant-it-data:/mnt/data"
kubectl apply -f secret.yml
kubectl apply -f config.yml
kubectl apply -f db.yml
kubectl apply -f cache.yml
kubectl apply -f server.yml
kubectl rollout status deployment/db-deployment
kubectl rollout status deployment/server-deployment
```

The NodePort service exposes the web app on `30100` and the API on `30101`:

```bash
minikube ip
```

Open `http://<minikube-ip>:30100` and enter `http://<minikube-ip>:30101` as the server URL. If the
Minikube driver does not expose NodePorts directly, run:

```bash
minikube service server-service
```

## Apply with Helm

Create a private values file rather than editing the checked-in defaults:

```bash
cd deployment
cp helm/values.yaml helm/my-values.yaml
# Replace example secrets and adjust storage before continuing.
helm upgrade --install plantit helm -f helm/my-values.yaml
```

The Kubernetes examples are not the release path used for the NAS deployment. Before production
use, replace local `hostPath` storage, add persistent upload storage, configure ingress/TLS, define
resource limits, and integrate your cluster's secret and backup systems.
