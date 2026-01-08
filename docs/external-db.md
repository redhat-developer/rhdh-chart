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

### Create secret with PostgreSQL connection properties:
````yaml
cat <<EOF | kubectl -n <your-namespace> create -f -
apiVersion: v1
kind: Secret
metadata:
 name: <cred-secret>
type: Opaque
stringData:
 POSTGRES_PASSWORD: <password>
 POSTGRES_PORT: "<db-port>"
 POSTGRES_USER: <username>
 POSTGRES_HOST: <db-host>
 PGSSLMODE: require #  for TLS connection
 NODE_EXTRA_CA_CERTS: <abs-path-to-pem-file> # for TLS connection, e.g. /opt/app-root/src/postgres-crt.pem
EOF
````

### Create secret with certificate(s):
(omit this step if you do not need TLS connection, maybe for testing purpose)

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

### Configure your Helm Chart (values.yaml):

````yaml
upstream:
 postgresql:
   enabled: false  # disable PostgreSQL instance creation 
 backstage:
   appConfig:
     backend:
       database:
         connection:  # configure Backstage DB connection parameters
           host: ${POSTGRES_HOST}
           port: ${POSTGRES_PORT}
           user: ${POSTGRES_USER}
           password: ${POSTGRES_PASSWORD}
   extraEnvVarsSecrets:
     - <cred-secret> # inject credentials secret to Backstage cont.
   extraEnvVars:
     - name: BACKEND_SECRET
       valueFrom:
         secretKeyRef:
           key: backend-secret
           name: '{{ include "rhdh.backend-secret-name" $ }}'
   extraVolumeMounts:
     - mountPath: /opt/app-root/src/dynamic-plugins-root
       name: dynamic-plugins-root
     - mountPath: /opt/app-root/src/postgres-crt.pem
       name: postgres-crt # inject certificate secret to Backstage cont.
       subPath: postgres-crt.pem
   extraVolumes:
     - ephemeral:
         volumeClaimTemplate:
           spec:
             accessModes:
               - ReadWriteOnce
             resources:
               requests:
                 storage: 1Gi
       name: dynamic-plugins-root
     - configMap:
         defaultMode: 420
         name: dynamic-plugins
         optional: true
       name: dynamic-plugins
     - name: dynamic-plugins-npmrc
       secret:
         defaultMode: 420
         optional: true
         secretName: dynamic-plugins-npmrc
     - name: postgres-crt
       secret:
         secretName: <crt-secret> 
````

### Apply Helm Chart:

````
helm install -n <your-namespace> <your_release_name> redhat-developer/backstage -f values.yaml 
````

