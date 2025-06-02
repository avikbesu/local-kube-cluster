.PHONY: all check-deps install start-cluster stop-cluster deploy-airflow

all: check-deps install start-cluster deploy-airflow

check-deps:
	@command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl not found. Installing..."; curl -LO "https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl"; chmod +x kubectl; sudo mv kubectl /usr/local/bin/; }
	@command -v kind >/dev/null 2>&1 || { echo >&2 "kind not found. Installing..."; curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64; chmod +x ./kind; sudo mv ./kind /usr/local/bin/kind; }
	@command -v helm >/dev/null 2>&1 || { echo >&2 "helm not found. Installing..."; curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; }

install:
	@echo "All dependencies are installed."

start-cluster:
	@echo "Starting single-node Kubernetes cluster with kind..."
	@kind create cluster --name local-cluster --wait 60s --config kind-config.yaml >/dev/null 2>&1 || echo "Cluster may already exist."

stop-airflow-port-forward:
	@echo "Stopping any running Airflow port-forward processes..."
	@pkill -f "kubectl port-forward svc/airflow-webserver" || echo "No port-forward process found."

stop-cluster: stop-airflow-port-forward
	@echo "Stopping and deleting kind cluster..."
	@kind delete cluster --name local-cluster

deploy-airflow:
	@echo "Creating 'airflow' namespace if it does not exist..."
	@kubectl get namespace airflow >/dev/null 2>&1 || kubectl create namespace airflow
	@echo "Deploying Apache Airflow with Helm into 'airflow' namespace..."
	@helm repo add apache-airflow https://airflow.apache.org
	@helm repo update
	@kubectl apply -f airflow/dags_pv.yaml -n airflow
	@kubectl apply -f airflow/dags_pvc.yaml -n airflow
	@helm upgrade --install airflow apache-airflow/airflow --namespace airflow --create-namespace -f airflow/values.yaml
	@echo "Airflow deployed successfully. You can access it via port-forwarding:"
	@echo "kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow"
	@echo "Visit http://localhost:8080 to access the Airflow UI."