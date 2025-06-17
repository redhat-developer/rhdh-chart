<!--
Thank you for your contribution! Complete the following fields to provide insight into the changes being requested as well as steps that you can take to ensure it meets all of the requirements

Please remember to link any JIRA issue(s) that this PR closes or relates to, as this helps provide more context to reviewers.

-->

## Description of the change

<!-- Describe the change being requested. -->

## Which issue(s) does this PR fix or relate to

<!-- List any related issues. -->

- _JIRA_issue_link_

## How to test changes / Special notes to the reviewer

<!--
Detailed instructions may help reviewers test this PR quickly and provide quicker feedback.
-->

## Checklist

- [ ] For each Chart updated, version bumped in the corresponding `Chart.yaml` according to [Semantic Versioning](http://semver.org/).
- [ ] For each Chart updated, variables are documented in the `values.yaml` and added to the corresponding README.md. The [pre-commit](https://pre-commit.com/) utility can be used to generate the necessary content. Use `pre-commit run -a` to apply changes. The [pre-commit Workflow](./workflows/pre-commit.yaml) will do this automatically for you if needed.
- [ ] JSON Schema template updated and re-generated the raw schema via the `pre-commit` hook.
- [ ] Tests pass using the [Chart Testing](https://github.com/helm/chart-testing) tool and the `ct lint` command.
- [ ] If you updated the [orchestrator-infra](../charts/orchestrator-infra) chart, make sure the versions of the [Knative CRDs](../charts/orchestrator-infra/crds) are aligned with the versions of the CRDs installed by the OpenShift Serverless operators declared in the [values.yaml](../charts/orchestrator-infra/values.yaml) file. See [Installing Knative Eventing and Knative Serving CRDs](../charts/orchestrator-infra/README.md#installing-knative-eventing-and-knative-serving-crds) for more details.
