# Local Kubernetes Cluster with Kind

This repository provides a Makefile to automate the setup of a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/), deploy [Apache Airflow](https://airflow.apache.org/) using Helm, and optionally deploy [MinIO](https://min.io/) as an S3-compatible object store. It manages dependencies, cluster lifecycle, and persistent storage for Airflow DAGs.

## Prerequisites

- Linux machine
- [make](https://www.gnu.org/software/make/)
- Internet connection (for downloading dependencies)

## Features

- Installs `kubectl`, `kind`, and `helm` if missing
- Creates a single-node Kubernetes cluster with kind
- Deploys Apache Airflow via Helm into a dedicated namespace
- Deploys MinIO with custom users and default buckets via Helm
- Manages Airflow DAGs persistent volumes
- Provides easy cluster and Airflow/MinIO teardown

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
3. Deploy Airflow into the cluster
4. Deploy MinIO (if you add a `deploy-minio` target in the Makefile)

### Individual Commands

- **Check/install dependencies only:**
  ```sh
  make check-deps
  ```

- **Start the cluster:**
  ```sh
  make start-cluster
  ```

- **Deploy Airflow:**
  ```sh
  make deploy-airflow
  ```

- **Deploy MinIO:**
  ```sh
  make deploy-minio
  ```

- **Stop Airflow port-forward (if running):**
  ```sh
  make stop-airflow-port-forward
  ```

- **Stop and delete the cluster:**
  ```sh
  make stop-cluster
  ```

## Accessing Airflow UI

After deploying Airflow, run the following command in a separate terminal to access the Airflow web UI:

```sh
kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow &
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

- **MinIO:**  
  - Buckets and users are defined in `minio/values.yaml`:
    ```yaml
    buckets:
      - name: local-bucket
        policy: none
        purge: false

    users:
      - accessKey: "user1"
        secretKey: "user@123"
        policy: "readwrite"
      - accessKey: "user2"
        secretKey: "user@123"
        policy: "readonly"
    ```
  - You can add more users or buckets as needed.

## Notes

- The Makefile will create the `airflow` namespace if it does not exist.
- Always run port-forward in the background (with `&`) for proper cleanup.
- To avoid issues with `stop-cluster`, always run port-forward in the background.

## Cleanup

To stop Airflow port-forwarding and delete the cluster:

```sh
make stop-cluster
```

---

**Happy experimenting with Airflow and MinIO on your local Kubernetes cluster!**