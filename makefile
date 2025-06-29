.PHONY: start check-deps install start-cluster stop-cluster 

start: install start-cluster deploy
default: start

check-deps:
	@command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl not found. Installing..."; curl -LO "https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl"; chmod +x kubectl; sudo mv kubectl /usr/local/bin/; }
	@command -v kind >/dev/null 2>&1 || { echo >&2 "kind not found. Installing..."; curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64; chmod +x ./kind; sudo mv ./kind /usr/local/bin/kind; }
	@command -v helm >/dev/null 2>&1 || { echo >&2 "helm not found. Installing..."; curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; }

install: check-deps
	@echo "All dependencies are installed."

start-cluster:
	@echo "Starting single-node Kubernetes cluster with kind..."
	@kind create cluster --name local-cluster --wait 60s --config kind-config.yaml >/dev/null 2>&1 || echo "Cluster may already exist."

stop: 
	@echo "Stopping and deleting kind cluster..."
	@kind delete cluster --name local-cluster

# Deploy components using Helm 
.PHONY: deploy-airflow deploy-minio deploy-postgres deploy
deploy-airflow:
	@echo "Creating 'airflow' namespace if it does not exist..."
	@kubectl get namespace airflow >logs/deploy-airflow.log 2>&1 || kubectl create namespace airflow
	@echo "Deploying Apache Airflow with Helm into 'airflow' namespace..."
	@helm repo add apache-airflow https://airflow.apache.org
	@helm repo update
	@kubectl apply -f airflow/dags_pv.yaml -n airflow >>logs/deploy-airflow.log 2>&1
	@kubectl apply -f airflow/dags_pvc.yaml -n airflow >>logs/deploy-airflow.log 2>&1
	@helm upgrade --install airflow apache-airflow/airflow --namespace airflow --create-namespace -f airflow/values.yaml >>logs/deploy-airflow.log 2>&1
	@echo "Airflow deployed successfully. You can access it via port-forwarding:"
	@echo "kubectl port-forward svc/airflow-api-server 8080:8080 -n airflow"
	@echo "Visit http://localhost:8080 to access the Airflow UI."

deploy-minio:
	@echo "Deploying MinIO with Helm into 'airflow' namespace..."
	@helm repo add minio https://charts.min.io/
	@helm repo update
	@helm upgrade --install minio minio/minio --namespace minio --create-namespace -f minio/values.yaml >logs/deploy-minio.log 2>&1
	@echo "MinIO deployed successfully. You can access it via port-forwarding:"
	@echo "kubectl port-forward svc/minio 9001:9001 -n minio"
	@echo "Visit http://localhost:9001 to access the MinIO UI."

deploy-postgres:
	@echo "Deploying PostgreSQL with Helm into 'db' namespace..."
	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm repo update
	@kubectl create namespace db >/dev/null 2>&1 || echo "Namespace 'db' already exists."
	@helm upgrade --install postgres bitnami/postgresql --namespace db --create-namespace -f postgres/values.yaml >logs/deploy-postgres.log 2>&1
	@echo "PostgreSQL deployed successfully."
	@echo "You can access PostgreSQL using the following command:"
	@echo "kubectl port-forward svc/postgres 5432:5432 -n db"
	@echo "Visit http://localhost:5432 to access the PostgreSQL database."

deploy: deploy-airflow deploy-minio deploy-postgres
	@echo "All components deployed successfully."

# Remove components from the cluster
.PHONY: remove-airflow remove-minio remove-postgres remove
remove-airflow:
	@helm uninstall airflow --namespace airflow >>logs/uninstall.log 2>&1
	@kubectl delete namespace airflow >>logs/uninstall.log 2>&1
	@echo "Airflow removed successfully."
remove-minio:
	@helm uninstall minio --namespace minio >>logs/uninstall.log 2>&1
	@kubectl delete namespace minio >>logs/uninstall.log 2>&1
	@echo "MinIO removed successfully."
remove-postgres:
	@helm uninstall postgres --namespace db >>logs/uninstall.log 2>&1
	@kubectl delete namespace db >>logs/uninstall.log 2>&1
	@echo "PostgreSQL removed successfully."
	
.PHONY: remove
remove: remove-airflow remove-minio remove-postgres
	@echo "All components removed successfully."
