# Catalog Index Configuration

The `backstage` Helm chart supports loading default plugin configurations from an OCI container image (catalog index). For general information about how the catalog index works, see [Using a Catalog Index Image for Default Plugin Configurations](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/installing-plugins.md#using-a-catalog-index-image-for-default-plugin-configurations).

By default, the `backstage` chart configures the catalog index image using `global.catalogIndex.image` with `registry`, `repository`, and `tag` fields. You can override these values in your values file to use a different version or a mirrored image:

```yaml
global:
  catalogIndex:
    image:
      registry: quay.io
      repository: rhdh/plugin-catalog-index
      tag: "1.9"
```

## Extra catalog index images

You can configure additional catalog index images alongside the primary one using `global.catalogIndex.extraImages`. Each extra image contributes catalog entities only to the Extensions UI — only the primary `CATALOG_INDEX_IMAGE` is used for extracting and handling the `dynamic-plugins.default.yaml`.

```yaml
global:
  catalogIndex:
    image:
      registry: quay.io
      repository: rhdh/plugin-catalog-index
      tag: "1.10"
    extraImages:
      - name: community
        registry: ghcr.io
        repository: redhat-developer/rhdh-plugin-community-index
        tag: "1.10"
      - registry: my-registry.example.com
        repository: my-org/my-rhdh-internal-plugin-catalog
        tag: "1.2.3"
```

Each entry requires `registry`, `repository`, and `tag` fields. The optional `name` field produces cleaner extraction directory names (e.g., `/extensions/extra/community/`); when omitted, the name is auto-derived from the image reference.

The chart constructs the `EXTRA_CATALOG_INDEX_IMAGES` environment variable for the `install-dynamic-plugins` init container as a comma-separated list. Named entries use the format `name=registry/repository:tag`, while unnamed entries use `registry/repository:tag`.

## Using a Private Registry

If your catalog index image is stored in a private registry that requires authentication, create a secret named `<release_name>-dynamic-plugins-registry-auth` containing an `auth.json` file with your registry credentials.

For detailed instructions on configuring private registry authentication, see the [official Red Hat Developer Hub documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html/installing_and_viewing_plugins_in_red_hat_developer_hub/assembly-third-party-plugins#proc-load-plugin-oci-image_assembly-install-third-party-plugins-rhdh).

## Extensions Catalog Entities

When the catalog index image is configured, the `backstage` chart instructs the RHDH `install-dynamic-plugins` init container to extract catalog entities from the catalog index image to a new `/extensions` volume mount by default.
This allows the extensions backend providers to automatically discover plugin metadata for display in the RHDH Extensions UI.

The extraction directory can be configured via the `CATALOG_ENTITIES_EXTRACT_DIR` environment variable in the `install-dynamic-plugins` init container.

More details in [Catalog Entities Extraction](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/installing-plugins.md#catalog-entities-extraction).
