# Twingate Kubernetes Operator with Vault Integration

[![CI](https://github.com/Twingate/kubernetes-operator/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/Twingate/kubernetes-operator/actions/workflows/ci.yaml)
[![Coverage Status](https://coveralls.io/repos/github/Twingate/kubernetes-operator/badge.svg?branch=main&t=7BQPrK)](https://coveralls.io/github/Twingate/kubernetes-operator?branch=main)
[![Dockerhub](https://img.shields.io/badge/dockerhub-images-info.svg?logo=Docker)](https://hub.docker.com/r/twingate/kubernetes-operator)

> [!IMPORTANT]
> **Beta:** The Twingate K8S Operator is currently in beta

This directory contains files for deploying the Twingate Kubernetes Operator with HashiCorp Vault integration for secure API key management.

## Overview

The Twingate Kubernetes Operator allows you to manage Twingate resources (connectors, resources, etc.) directly from your Kubernetes cluster. This implementation uses HashiCorp Vault to securely store and retrieve the Twingate API key.

## Files

- `values.yaml` - Configuration values for the Twingate operator
- `create-secret.sh` - Script to create Kubernetes secret with API key from Vault
- `twingate-secret.yaml` - Template for the Kubernetes secret
- `fetch-network-id.sh` - Utility to fetch Remote Network IDs from Twingate API

## Prerequisites

- Kubernetes cluster (1.16+)
- Twingate account with a Remote Network configured
- HashiCorp Vault with the Twingate API key stored at `infrastructure/twingate`
- Vault token with read permissions for the API key

## Installation

The installation is handled through the main Makefile target `deploy-twingate`. This will:

1. Retrieve the Twingate API key from Vault
2. Create a Kubernetes secret with the API key
3. Deploy the Twingate operator using the official Helm chart

```bash
make deploy-twingate
```

## Manual Deployment

If you need to deploy manually:

1. Create the secret with API key from Vault:
   ```bash
   ./operators/twingate/create-secret.sh
   ```

2. Deploy the Twingate operator:
   ```bash
   helm upgrade --install twop \
     oci://ghcr.io/twingate/helmcharts/twingate-operator \
     --namespace twingate-system \
     --wait \
     -f operators/twingate/values.yaml
   ```

## Finding Your Remote Network ID

To find your Remote Network ID, use the provided utility script:

```bash
VAULT_TOKEN=<your-vault-token> ./operators/twingate/fetch-network-id.sh
```

The script will retrieve the API key from Vault and list all available Remote Networks with their IDs. Update the `remoteNetworkId` field in `values.yaml` with the appropriate ID.

[Wiki][1]  |  [Getting Started][2]  |  [API Reference][3]

[1]: https://github.com/Twingate/kubernetes-operator/wiki
[2]: https://github.com/Twingate/kubernetes-operator/wiki/Getting-Started
[3]: https://github.com/Twingate/kubernetes-operator/wiki/API-Reference

## Changelog

See [CHANGELOG](./CHANGELOG.md)

## Support

- For general issues using this operator please open a GitHub issue.
- For account specific issues, please visit the [Twingate forum](https://forum.twingate.com/)
 or open a [support ticket](https://help.twingate.com/)

## Developers

See [developer guide](./DEVELOPER.md)