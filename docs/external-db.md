# External DB integration

Backstage hosts the data in a [PostgreSQL database](https://backstage.io/docs/getting-started/config/database/).
By default, the Helm Chart creates and manages a local instance of PostgreSQL in the same namespace as the Backstage deployment but it also allows to switch this off and configure an external database server instead.
Usually, external connection requires more security, so, this instruction includes steps to configure SSL/TLS.

### Configure your external PostgreSQL instance
As a prerequisite, you have to know:
- **db-host** - your PostgreSQL instance DNS or IP address 
- **db-port** - your PostgreSQL instance port number (usually 5432)
- **username** - to connect to your PostgreSQL instance
- **password** - to connect to your PostgreSQL instance

**NOTE:** By default, Backstage uses databases for each plugin and automatically creates them if none are found, so in addition to PSQL Database level privileges, the user may need Create Database privilege.  

In addition, to get your database connection secured with SSL/TLS, you also need certificates in the form of PEM file. 

You can find configuration guidelines for:
- [AWS RDS PostgreSQL](https://github.com/redhat-developer/rhdh-operator/blob/main/docs/external-db.md#aws-rds-postgresql)
- [Azure Database PostgreSQL](https://github.com/redhat-developer/rhdh-operator/blob/main/docs/external-db.md#azure-db-postgresql)

If you want to move Backstage database from local to external, here is a [Migration Guide](https://github.com/redhat-developer/rhdh-operator/blob/main/docs/db_migration.md).

### Create secret with the database password:
````yaml
cat <<EOF | kubectl -n <your-namespace> create -f -
apiVersion: v1
kind: Secret
metadata:
  name: <cred-secret>
type: Opaque
stringData:
  POSTGRES_PASSWORD: <password>
EOF
````

### Configure your Helm Chart (values.yaml):

````yaml
postgresql:
  enabled: false

externalDatabase:
  host: <db-host>
  port: <db-port>
  user: <username>
  existingSecretRef:
    name: <cred-secret>
    key: POSTGRES_PASSWORD
````

The chart injects `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` as environment variables from the `externalDatabase` values and the referenced secret. The default `appConfig.backend.database.connection` already references these variables, so no `appConfig` override is needed for the database connection.

### TLS configuration (optional)

If your external database requires SSL/TLS, create two additional resources: a secret with the TLS environment variables and a secret with the certificate.

#### TLS environment secret:
````yaml
cat <<EOF | kubectl -n <your-namespace> create -f -
apiVersion: v1
kind: Secret
metadata:
  name: <tls-env-secret>
type: Opaque
stringData:
  PGSSLMODE: require
  NODE_EXTRA_CA_CERTS: /opt/app-root/src/postgres-crt.pem
EOF
````

#### Certificate secret:
````yaml
cat <<EOF | kubectl -n <your-namespace> create -f -
apiVersion: v1
kind: Secret
metadata:
  name: <crt-secret>
type: Opaque
stringData:
  postgres-crt.pem: |-
    -----BEGIN CERTIFICATE-----
    MIIFqDCCA5CgAwIBAgIQHtOXCV/YtLNHcB6qvn9FszANBgkqhkiG9w0BAQwFADBl
    ... 
````

#### Add TLS fields to your values.yaml:
````yaml
extraEnvFrom:
  - secretRef:
      name: <tls-env-secret>

extraVolumeMounts:
  - mountPath: /opt/app-root/src/postgres-crt.pem
    name: postgres-crt
    subPath: postgres-crt.pem

extraVolumes:
  - name: postgres-crt
    secret:
      secretName: <crt-secret>
````

### Apply Helm Chart:

````
helm install -n <your-namespace> <your_release_name> redhat-developer/redhat-developer-hub -f values.yaml 
````
