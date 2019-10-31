# openshift-jenkins-vault-agent

This project provides a Jenkins pipeline agent with Vault preinstalled for use
with OpenShift Jenkins Pipeline jobs. It works in conjunction with the Jenkins
master and basic agent provisioned by `oc process -n default jenkins-ephemeral
| oc apply -f -`, as described
[here](https://docs.openshift.com/container-platform/3.4/using_images/other_images/jenkins.html#jenkins-creating-jenkins-service-from-template).

## Use

The agent can be built and provisioned with `./hack/deploy.sh`. This builds the
agent's image in the `default` namespace and configures it for use as an agent
in the current (`oc project -q`) namespace.

Once build/provisioning is complete, the agent can be used in a Jenkins
pipeline by specifying `agent { label 'vault'}` within a `pipeline` element.
For example, the following script is used in tests; run it in OpenShift with
`./test/test-pipeline.sh`.

```groovy
pipeline {
  agent { label 'vault' }
  stages {
    stage('Test Agent') {
      steps {
        sh 'echo calling: vault version'
        sh 'vault version'
      }
    }
  }
}
```

### Background

[./hack/agent-configmap-template.yaml](./hack/agent-configmap-template.yaml) is
applied to the `default` and current context namespaces using `oc process -f
./hack/agent-configmap-templates.yaml | oc apply -f -`. The [OpenShift
jenkins-sync-plugin](https://github.com/openshift/jenkins-sync-plugin) monitors
for configmaps with the label `role=jenkins-slave` and uses their templates to
  configure pods for agents on demand.
