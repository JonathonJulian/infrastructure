# Twingate Resources Helm Chart

This chart allows you to declaratively manage any number of TwingateConnector, TwingateResource, and TwingateResourceAccess objects in your cluster.

## Usage

1. Add your connectors, resources, and access rules to `values.yaml`.
2. Install or upgrade the chart:

```bash
helm upgrade --install twingate-resources ./charts/twingate-minio-resources -n twingate-system
```

## Example values.yaml

```yaml
connectors:
  - name: minio-connector
    namespace: twingate-system
    imagePolicy:
      provider: dockerhub
      schedule: "0 0 * * *"

resources:
  - name: minio-resource
    namespace: twingate-system
    spec:
      name: "MinIO Object Storage"
      address: "minio.default.svc.cluster.local"
      alias: "minio.local"

access:
  - name: minio-access
    namespace: twingate-system
    spec:
      resourceRef:
        name: minio-resource
        namespace: twingate-system
      principalExternalRef:
        type: group
        name: "Administrators"
```

## Adding More Resources

Just add more entries to the `resources` and `access` arrays in your `values.yaml`.

## Notes
- This chart is generic and can be used for any Twingate-exposed service, not just MinIO.
- You must have the Twingate Operator installed in your cluster.