## **Documentation for the script to handle CLI helm installation for OCP**

## **Overview**

The purpose of the [`install.sh` script](./install.sh) is to simplify and automate the installation process of this Helm Chart on OpenShift Container Platform (OCP) clusters. Instead of requiring users to follow a lengthy and potentially error-prone series of manual steps, this script consolidates the process into a single, reusable command that can:

* Detect if the OpenShit Client ([`oc`](https://docs.openshift.com/container-platform/4.16/cli_reference/openshift_cli/getting-started-cli.html)) is installed; fail if not found and report the error to the user with a call to action (installing it).

* If cluster router base can be detected, use that value to update the helm chart installation; if not, fail and request user pass in command line flag as cluster router base could not be detected (can test this failure case with dev sandbox; can test passing case with clusterbot).

## **Prerequisites**

1. Ensure that `oc` (for OpenShift) is installed. See https://docs.openshift.com/container-platform/4.16/cli_reference/openshift_cli/getting-started-cli.html#installing-openshift-cli for further instructions.
2. Ensure that you are logged into an OCP cluster and that it is running. See [Logging in to the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/cli_tools/openshift-cli-oc#cli-logging-in_cli-developer-commands).
3. git
4. [Helm](https://helm.sh/docs/intro/install/)

## **Installation Steps**

1. **Download the Script** - Clone the repository and navigate to the `scripts` directory: \

  ```shell
git clone --depth 1 https://github.com/redhat-developer/rhdh-chart.git
cd rhdh-charts/scripts
```

1. **Run the Script** - Execute the script to install the Helm chart. The script will automatically detect that you are using `oc` and ensure you are logged into your cluster. \
`./install.sh`

   **Specify Router Base** - If the script cannot automatically detect the cluster router base, you can provide it manually using the `--router-base` flag, example:\
      `./install.sh --router-base <your-router-base>`

   **Specify Release Name** - To install the Helm chart with a custom release name: \
   `./install.sh --release-name myrelease`

    **Generate a Release Name** - To generate a name for the Helm release: \
    `./install.sh --generate-name`

1. **Specify Namespace** - To specify the namespace for the Helm release: \
`./install.sh --namespace mynamespace`

    **Specify Custom Values File** - To use a custom values file for the Helm chart: \
   `./install.sh --values /path/to/values.yaml`

## **Troubleshooting**

* Missing <code>oc</code> - </strong> If the script outputs an error indicating that neither <code>oc</code> nor <code>kubectl</code> is installed, please install the appropriate CLI tool for your cluster:
    * For OpenShift: Install <code>oc</code>

* <strong>Not Logged Into Cluster: </strong> If you are not logged into a cluster, follow these steps to log in:
    * For OpenShift:
 `oc login <your-cluster-url>`

* <strong>Router Base Detection Failed: - </strong> If the script cannot detect the cluster router base, manually provide it using the <code>--router-base</code> flag as shown in the example usage section.

* <strong>Error: INSTALLATION FAILED:</strong>

     An error occurred while checking for chart dependencies. You may need to run `helm dependency build` to fetch missing dependencies: found in Chart.yaml, but missing in charts/ directory: common, backstage:
  `helm dependency build`

An example of the installation output should be:

Using router base: example.com

NAME: ...

LAST DEPLOYED: ...

NAMESPACE: ...

STATUS: ...

REVISION: ...

Helm installation completed successfully.

You can run: `helm list --namespace $myProject` to confirm this installation.
