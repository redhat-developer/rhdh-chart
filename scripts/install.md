## **Documentation for the script to handle CLI helm installation for OCP**

Jira Issue - [RHIDP-2706](https://issues.redhat.com/browse/RHIDP-2706)


## **Overview**

The purpose of the `install-helm.sh` script is to simplify and automate the installation process of Helm charts on OpenShift Container Platform (OCP) clusters. Instead of requiring users to follow a lengthy and potentially error-prone series of manual steps, this script consolidates the process into a single, reusable command that can:



* Detect if oc is installed; fail if not found and report the error to the user with a call to action re: installing it.
* Detect if the user is logged into a cluster and fail if not with the call to action (oc command to log in).
* If cluster router base can be detected, use that value to update the helm chart installation; if not, fail and request user pass in command line flag as cluster router base could not be detected (can test this failure case with dev sandbox; can test passing case with clusterbot).


## **Prerequisites**



1. Ensure that `oc` (for OpenShift) is installed.
2. Ensure that you are logged into an OCP cluster and that it is running.


## **Installation Steps**

**Download the Script \
**Clone the repository and navigate to the `scripts` directory:

**Make the Script Executable \
**Before running the script, make sure it has executable permissions:

**Run the Script \
**Execute the script to install the Helm chart. The script will automatically detect that you are using `oc` and ensure you are logged into your cluster.

**Specify Router Base**

If the script cannot automatically detect the cluster router base, you can provide it manually using the `-router-base` flag. \


Example:


### **Specify Release Name**

To install the Helm chart with a custom release name


### **Generate a Release Name**

To generate a name for the Helm release


### **Specify Namespace**

To specify the namespace for the Helm release


### **Specify Custom Values File**

To use a custom values file for the Helm chart


### **Troubleshooting**



* **Missing <code>oc</code>: \
 \
</strong> If the script outputs an error indicating that neither <code>oc</code> nor <code>kubectl</code> is installed, please install the appropriate CLI tool for your cluster: \

    * For OpenShift: Install <code>oc</code>
    * For Kubernetes: Install <code>kubectl</code>
* <strong>Not Logged Into Cluster: \
 \
</strong> If you are not logged into a cluster, follow these steps to log in: \

    * For OpenShift:
* <strong>Router Base Detection Failed: \
 \
</strong> If the script cannot detect the cluster router base, manually provide it using the <code>--router-base</code> flag as shown in the example usage section. \

* <strong>Error: INSTALLATION FAILED:</strong>

     An error occurred while checking for chart dependencies. You may need to run `helm dependency build` to fetch missing dependencies: found in Chart.yaml, but missing in charts/ directory: common, backstage:

    * If you get an error saying: “Error: Chart.yaml file is missing”. Change the directory to the backstage directory for example: cd ../charts/backstage/ Then run helm dependency build again.
    * You should then see an error like:

        “Error: no repository definition for https://charts.bitnami.com/bitnami, https://backstage.github.io/charts. Please add the missing repos via 'helm repo add'”


        If you received this error simply add the repositories like this:

    * Your output should be:

        "bitnami" has been added to your repositories


        "backstage" has been added to your repositories

    * Next run: helm repo list
        * You should see:

            NAME                           URL                                           


            redhat-developer        https://redhat-developer.github.io/rhdh-chart/


            bitnami                        https://charts.bitnami.com/bitnami            


            backstage                   https://backstage.github.io/charts            


Then run:

The output should be:

Hang tight while we grab the latest from your chart repositories...

...Successfully got an update from the "backstage" chart repository

...Successfully got an update from the "redhat-developer" chart repository

...Successfully got an update from the "bitnami" chart repository

Update Complete. ⎈Happy Helming!⎈

Saving 2 charts

Downloading common from repo https://charts.bitnami.com/bitnami

Downloading backstage from repo https://backstage.github.io/charts

Deleting outdated charts

Next, navigate to the install-helm.sh file in the scripts directory and run:

An example of the output should be:

Using router base: example.com

NAME: my-release

LAST DEPLOYED: Tue Jun 18 11:32:15 2024

NAMESPACE: default

STATUS: deployed

REVISION: 1

Helm installation completed successfully.

You can run: helm version to confirm this installation the output should be:

version.BuildInfo{Version:"v3.11", GitCommit:"", GitTreeState:"", GoVersion:"go1.21.6"}

**Script Details**

The `install-helm.sh` script performs the following tasks:



1. Check if `oc `is installed.
2. Verifies that the user is logged into a cluster.
3. Attempts to detect the cluster router base.
4. Updates the Helm chart configuration with the detected or provided router base.
5. Install the Helm chart using the configured settings.

Following the above instructions, you can easily and reliably install Helm charts on your K8s or OCP cluster using the `install-helm.sh` script.
