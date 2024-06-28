## **Documentation for the script to handle CLI helm installation for OCP**

## **Overview**

The purpose of the `install-helm.sh` script is to simplify and automate the installation process of Helm charts on OpenShift Container Platform (OCP) clusters. Instead of requiring users to follow a lengthy and potentially error-prone series of manual steps, this script consolidates the process into a single, reusable command that can:



* Detect if oc is installed; fail if not found and report the error to the user with a call to action re: installing it.
* Detect if the user is logged into a cluster and fail if not with the call to action (oc command to log in).
* If cluster router base can be detected, use that value to update the helm chart installation; if not, fail and request user pass in command line flag as cluster router base could not be detected (can test this failure case with dev sandbox; can test passing case with clusterbot).


## **Prerequisites**



1. Ensure that `oc` (for OpenShift) is installed.
2. Ensure that you are logged into an OCP cluster and that it is running.


## **Installation Steps**

1. **Download the Script** - Clone the repository and navigate to the `scripts` directory: \
`git clone <https://github.com/><your-username>/rhdh-chart.git
cd rhdh-chart/scripts`


2. **Make the Script Executable** - Before running the script, make sure it has executable permissions: \
`chmod +x install.sh`


3. **Run the Script** - Execute the script to install the Helm chart. The script will automatically detect that you are using `oc` and ensure you are logged into your cluster. \
`./install.sh`


   **Specify Router Base** - If the script cannot automatically detect the cluster router base, you can provide it manually using the `-router-base` flag, example:\
      `./install.sh --router-base <your-router-base>`


4. **Specify Release Name** - To install the Helm chart with a custom release name: \
`./install.sh --release-name myrelease`

    **Generate a Release Name** - To generate a name for the Helm release: \
    `./install.sh --generate-name`

5. **Specify Namespace** - To specify the namespace for the Helm release: \
`./install.sh --namespace mynamespace`


    **Specify Custom Values File** - To use a custom values file for the Helm chart: \
   `./install.sh --values /path/to/values.yaml`




## **Troubleshooting**


* Missing <code>oc</code> - </strong> If the script outputs an error indicating that neither <code>oc</code> nor <code>kubectl</code> is installed, please install the appropriate CLI tool for your cluster:
    * For OpenShift: Install <code>oc</code>
    * For Kubernetes: Install <code>kubectl</code>
    

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

You can run: `helm version` to confirm this installation.
