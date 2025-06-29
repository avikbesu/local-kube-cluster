# Local Kubernetes Cluster with Kind

This repository provides a Makefile to automate the setup of a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/), deploy [Apache Airflow](https://airflow.apache.org/) using Helm, and optionally deploy [MinIO](https://min.io/) as an S3-compatible object store. It manages dependencies, cluster lifecycle, and persistent storage for Airflow DAGs.

## Prerequisites

- Linux machine
- [make](https://www.gnu.org/software/make/)
- Internet connection (for downloading dependencies)

## Features

- Installs `kubectl`, `kind`, and `helm` if missing
- Creates a single-node Kubernetes cluster with kind
- Deploys PostgreSQL via Helm into a dedicated namespace for Airflow metadata
- Deploys Apache Airflow via Helm configured to use external PostgreSQL
- Deploys MinIO with custom users and default buckets via Helm
- Manages Airflow DAGs persistent volumes
- Provides easy cluster and Airflow/PostgreSQL/MinIO teardown

## Usage

Clone this repository and enter the directory:

```sh
git clone <repo-url>
cd local-kube-cluster
```

### Start Everything

```sh
make
```
This will:
1. Check and install dependencies (`kubectl`, `kind`, `helm`)
2. Start a local kind cluster
3. Deploy PostgreSQL into the cluster
4. Deploy Airflow configured to use the external PostgreSQL
5. Deploy MinIO

### Individual Commands

| Command                         | Description                           |
|----------------------------------|---------------------------------------|
| `make check-deps`               | Check/install dependencies only       |
| `make start`                    | Start the cluster                     |
| `make deploy-postgres`          | Deploy PostgreSQL                     |
| `make deploy-airflow`           | Deploy Airflow (uses external Postgres)|
| `make deploy-minio`             | Deploy MinIO                          |
| `make stop`                     | Stop and delete the cluster           |
| `make remove`                   | Remove all deployed components        |

## Accessing Airflow UI

After deploying Airflow, run the following command in a separate terminal to access the Airflow web UI:

```sh
kubectl port-forward svc/airflow-api-server 8080:8080 -n airflow &
```

Then visit [http://localhost:8080](http://localhost:8080) in your browser.

## Accessing MinIO UI

After deploying MinIO, run:

```sh
kubectl port-forward svc/minio 9000:9000 -n minio &
kubectl port-forward svc/minio-console 9001:9001 -n minio &
```

Then visit [http://localhost:9001](http://localhost:9001) for the MinIO Console.  
Default credentials are set in `minio/values.yaml` (e.g., `minioadmin` / `min!0@Dmin`).

## Configuration

- **Airflow:**  
  - Persistent volumes for DAGs are applied from `airflow/dags_pv.yaml` and `airflow/dags_pvc.yaml`.
  - The Airflow Helm chart values can be customized in `airflow/values.yaml`.
  - Airflow is configured to use an external PostgreSQL database (see `externalDatabase` section in `airflow/values.yaml`).

- **PostgreSQL:**  
  - Credentials and database name are set in `postgres/values.yaml`.
  - The service is exposed within the cluster as `postgres.db.svc.cluster.local:5432`.

- **MinIO:**  
  - Buckets and users are defined in `minio/values.yaml`.
  - You can add more users or buckets as needed.

## Notes

- The Makefile will create the `airflow` namespace if it does not exist.
- Always run port-forward in the background (with `&`) for proper cleanup.
- To avoid issues with `stop`, always run port-forward in the background.

## Cleanup

To stop Airflow port-forwarding and delete the cluster:

```sh
make remove
make stop
```

---

**Happy experimenting with Airflow and MinIO on your local Kubernetes cluster!**