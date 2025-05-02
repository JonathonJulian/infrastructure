# MinIO Object Storage

This chart deploys MinIO object storage in a Kubernetes cluster.

## Overview

MinIO is a high-performance, S3-compatible object storage system. This deployment configures MinIO for the following use cases:

- Persistent storage for application data
- Terraform state storage
- Blockchain node snapshots (Arbitrum and Ethereum)
- Loki log chunks

## Prerequisites

- Kubernetes cluster with StorageClass `proxmox-ssd` available
- Helm v3 or later
- Access to pull MinIO container images

## Configuration

The MinIO deployment is configured with:

- 3000Gi storage provisioned via Proxmox CSI driver
- Default buckets pre-configured for various workloads
- Ingress enabled at path `/minio` and console at `/minio-console`
- Default access credentials (should be changed in production)

## Installation

```bash
# Install the chart with the release name 'minio'
helm install minio ./charts/minio

# Alternatively, with custom values
helm install minio ./charts/minio -f values.custom.yaml
```

## Access MinIO

Once deployed, MinIO can be accessed:

- **API Endpoint**: http://minio.local/minio
- **Console**: http://minio.local/minio-console

Default credentials:
- Username: `minioadmin`
- Password: `minioadmin`

## Storage Considerations

The deployment uses a single PVC for data storage. In production environments, consider:

1. Increasing replicas for better availability
2. Configuring backup solutions for critical data
3. Using node affinity for placement control

## Troubleshooting

If pods fail to start, check:

1. PVC creation status
2. CSI driver functionality
3. Node capacity for CPU/memory requests