# Catalog Index Configuration

The Helm chart supports loading default plugin configurations from an OCI container image (catalog index). For general information about how the catalog index works, see [Using a Catalog Index Image for Default Plugin Configurations](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/installing-plugins.md#using-a-catalog-index-image-for-default-plugin-configurations).

By default, the chart sets `pluginCatalogIndex.image` to `quay.io/rhdh/plugin-catalog-index:1.9`.

## Overriding the Catalog Index Image

To use a different catalog index image, such as a newer version or a mirrored image, use the `pluginCatalogIndex.image` field in your values file:

```yaml
# values.yaml
pluginCatalogIndex:
  image: "quay.io/rhdh/plugin-catalog-index:1.9"
```

Alternatively, you can override it via the command line:

```console
helm upgrade -i <release_name> redhat-developer/backstage \
  --set pluginCatalogIndex.image="quay.io/rhdh/plugin-catalog-index:1.9"
```

## Disabling the Catalog Index

To disable the catalog index feature and use only the `dynamic-plugins.default.yaml` bundled in the container image, set the image to an empty string:

```yaml
# values.yaml
pluginCatalogIndex:
  image: ""
```

## Using a Private Registry

If your catalog index image is stored in a private registry that requires authentication, you can provide credentials by using the `dynamic-plugins-registry-auth` secret.

The `auth.json` file is the standard [containers-auth.json(5)](https://github.com/containers/image/blob/main/docs/containers-auth.json.5.md) format used by `skopeo`, `podman`, and other container tools. It stores registry credentials that allow these tools to pull images from authenticated registries.

**1:** Create the `auth.json` file with your registry credentials:

```json
{
  "auths": {
    "my-registry.example.com": {
      "auth": "dXNlcm5hbWU6cGFzc3dvcmQ="
    }
  }
}
```

The `auth` value is a base64-encoded string of `username:password`. You can generate it with the following commands:

```console
echo -n 'myusername:mypassword' | base64
```

**2:** Create the Kubernetes secret from the `auth.json` file:

```console
kubectl create secret generic <release_name>-dynamic-plugins-registry-auth \
  --from-file=auth.json=./auth.json \
  -n <namespace>
```

Alternatively, you can use a declarative YAML manifest:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <release_name>-dynamic-plugins-registry-auth
type: Opaque
stringData:
  auth.json: |
    {
      "auths": {
        "my-registry.example.com": {
          "auth": "dXNlcm5hbWU6cGFzc3dvcmQ="
        }
      }
    }
```

This secret is automatically mounted into the `install-dynamic-plugins` init container at `/opt/app-root/src/.config/containers`, allowing `skopeo` to authenticate when pulling images from private registries.
