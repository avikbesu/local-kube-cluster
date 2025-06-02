# Local Kubernetes Cluster with Airflow

This repository provides a Makefile to automate the setup of a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/) and deploy [Apache Airflow](https://airflow.apache.org/) using Helm. It also manages dependencies and cluster lifecycle tasks.

## Prerequisites

- Linux machine
- [make](https://www.gnu.org/software/make/)
- Internet connection (for downloading dependencies)

## Features

- Installs `kubectl`, `kind`, and `helm` if missing
- Creates a single-node Kubernetes cluster with kind
- Deploys Apache Airflow via Helm into a dedicated namespace
- Manages Airflow DAGs persistent volumes
- Provides easy cluster and Airflow teardown

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

## Notes

- The Makefile will create the `airflow` namespace if it does not exist.
- Persistent volumes for DAGs are applied from `airflow/dags_pv.yaml` and `airflow/dags_pvc.yaml`.
- The Airflow Helm chart values can be customized in `airflow/values.yaml`.
- Always run port-forward in the background (with `&`) for proper cleanup.

## Cleanup

To stop Airflow port-forwarding and delete the cluster:

```sh
make stop-cluster
```

---

**Happy experimenting with Airflow on your local Kubernetes cluster!**