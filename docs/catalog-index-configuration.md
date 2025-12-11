# Catalog Index Configuration

The catalog index is an OCI artifact that contains `dynamic-plugins.default.yaml`, which defines the default set of dynamic plugins to be installed. The Helm chart automatically configures the `install-dynamic-plugins` init container to pull and extract this catalog index.

By default, the chart sets the `CATALOG_INDEX_IMAGE` environment variable in the `install-dynamic-plugins` init container:

```yaml
env:
  - name: CATALOG_INDEX_IMAGE
    value: "quay.io/rhdh/plugin-catalog-index:1.9"
```

The `install-dynamic-plugins.py` script:
1. Pulls the catalog index OCI image using `skopeo`
2. Extracts the image layers to a temporary directory (`.catalog-index-temp`)
3. Locates `dynamic-plugins.default.yaml` within the extracted content
4. Replaces the `dynamic-plugins.default.yaml` reference in your `includes` list with the extracted catalog index version

### Overriding the Catalog Index Image

To use a different catalog index image, such as a newer version or a mirrored image, use the `global.dynamic.catalogIndex.image` field in your values file:

```yaml
# values.yaml
global:
  dynamic:
    catalogIndex:
      image: "quay.io/rhdh/plugin-catalog-index:1.9"
```

Alternatively, you can override it via the command line:

```console
helm upgrade -i <release_name> redhat-developer/backstage \
  --set global.dynamic.catalogIndex.image="quay.io/rhdh/plugin-catalog-index:1.9"
```

### Disabling the Catalog Index

To disable the catalog index feature entirely and not pull any external catalog index image, set the image to an empty string:

```yaml
# values.yaml
global:
  dynamic:
    catalogIndex:
      image: ""
```

When disabled, the `install-dynamic-plugins.py` script skips the catalog index extraction and relies solely on the `dynamic-plugins.default.yaml` file bundled within the Backstage container image.

### Using a Private Registry

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
