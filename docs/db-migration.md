# Local database migration

The chart-managed local PostgreSQL database is upgraded with PostgreSQL's [Upgrading Data via pg_dumpall](https://www.postgresql.org/docs/current/upgrading.html#UPGRADING-VIA-PGDUMPALL): dump the PostgreSQL 15 databases, initialize a fresh PostgreSQL 18 cluster, and restore the logical backup. Backstage must be stopped for the whole procedure.

## Preparation

The commands assume one release with the default database resources and a Backstage Deployment:

```bash
NAMESPACE=<your-namespace>
RELEASE=<release-name>
BACKSTAGE_WORKLOAD="deployment/${RELEASE}-developer-hub"
DB_STATEFULSET="${RELEASE}-postgresql"
DB_POD="${DB_STATEFULSET}-0"
DB_PVC="data-${DB_POD}"
```

Resource names depend on `nameOverride` and `fullnameOverride`. Verify them before you continue:

```bash
kubectl -n "$NAMESPACE" get deployment,statefulset,pvc \
  -l "app.kubernetes.io/instance=${RELEASE}"
```

The database credentials are in the `<release>-postgresql` Secret, or in the Secret set in `postgresql.auth.existingSecret`. Keep this Secret, your values file, and the database backup until the upgrade is verified.

## Stop Backstage

Save the release values, then stop Backstage so that no client reads or writes the database during the copy:

```bash
helm get values "$RELEASE" -n "$NAMESPACE" -o yaml > values-before-migration.yaml
kubectl -n "$NAMESPACE" scale "$BACKSTAGE_WORKLOAD" --replicas=0
kubectl -n "$NAMESPACE" wait --for=delete pod \
  -l "app.kubernetes.io/instance=${RELEASE},app.kubernetes.io/component=backstage" --timeout=5m
```

If `autoscaling.enabled` is `true`, disable autoscaling for the migration, because the replica count is not rendered in that case.

## Upgrade PostgreSQL 15 to 18

1. Check that the source server reports version `15.x`, and save the database list and locale information for comparison after the restore:

   ```bash
   kubectl -n "$NAMESPACE" exec "$DB_POD" -- \
     psql -X -U postgres -d postgres -c 'SHOW server_version;' -c '\l'
   ```

2. Dump all databases and roles to a file on your local machine. Confirm that the command succeeds and the file is nonempty before continuing:

   ```bash
   kubectl -n "$NAMESPACE" exec "$DB_POD" -- \
     pg_dumpall -U postgres > postgresql-15.sql
   test -s postgresql-15.sql
   ```

3. Delete the database StatefulSet and its persistent volume claim. This removes the PostgreSQL 15 data, so keep the successful dump. The credentials Secret is not affected:

   ```bash
   kubectl -n "$NAMESPACE" delete statefulset "$DB_STATEFULSET" --wait=true
   kubectl -n "$NAMESPACE" wait --for=delete "pod/$DB_POD" --timeout=5m
   kubectl -n "$NAMESPACE" delete pvc "$DB_PVC" --wait=true
   ```

   The data volume has to be replaced before the upgrade, because `helm upgrade` always renders the database StatefulSet with one replica.

4. Remove any PostgreSQL 15 pin from your values, then upgrade the release with Backstage still stopped, so that it cannot create empty databases before the restore:

   ```bash
   helm upgrade "$RELEASE" redhat-developer/redhat-developer-hub \
     -n "$NAMESPACE" -f values.yaml --set replicaCount=0
   ```

   If you are migrating from the `backstage` chart, use your migrated values as described in the [migration guide](../charts/rhdh/docs/migration-from-backstage-chart.md). In disconnected installations, mirror the PostgreSQL 18 image to your registry first and set `postgresql.image.registry` accordingly.

5. Wait for PostgreSQL 18 and check the server version. It must report `18.x` before you restore the backup:

   ```bash
   kubectl -n "$NAMESPACE" rollout status "statefulset/$DB_STATEFULSET" --timeout=10m
   kubectl -n "$NAMESPACE" exec "$DB_POD" -- \
     psql -X -U postgres -d postgres -c 'SHOW server_version;'
   ```

6. Restore the dump into the fresh database cluster:

   ```bash
   kubectl -n "$NAMESPACE" exec -i "$DB_POD" -- \
     psql -X -U postgres -d postgres < postgresql-15.sql
   ```

   The only expected error is `ERROR: role "postgres" already exists`, because the new cluster already has this bootstrap role. Review the restore output for any other errors before proceeding; `psql` can finish successfully despite SQL errors.

7. List the restored databases and compare their names, encodings, and locales with the source. Check important application data as well:

   ```bash
   kubectl -n "$NAMESPACE" exec "$DB_POD" -- \
     psql -X -U postgres -d postgres -c '\l'
   ```

   Logical restore rebuilds indexes using the target image's collation libraries and records their current versions. The following check should return no rows:

   ```bash
   kubectl -n "$NAMESPACE" exec "$DB_POD" -- psql -X -U postgres -d postgres -c \
     'SELECT datname FROM pg_database
      WHERE datallowconn
        AND datcollversion IS DISTINCT FROM pg_database_collation_actual_version(oid);'
   ```

8. Restart Backstage with the original replica count, and re-enable autoscaling if you disabled it:

   ```bash
   helm upgrade "$RELEASE" redhat-developer/redhat-developer-hub \
     -n "$NAMESPACE" -f values.yaml
   kubectl -n "$NAMESPACE" rollout status "$BACKSTAGE_WORKLOAD" --timeout=15m
   ```

   Verify that Backstage starts successfully and that the expected plugin data is available. Retain the backup until application verification is complete.

The RHDH Operator documents the same procedure for Operator-managed databases: [Local database migration](https://github.com/redhat-developer/rhdh-operator/blob/main/docs/db_migration.md).
