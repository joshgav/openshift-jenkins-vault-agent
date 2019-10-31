#! /usr/bin/env bash

this_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
root_dir=$(dirname ${this_dir})

export namespace_name=default
export imagestream_name=jenkins-vault-agent
export pull_secret_name=redhat-registry-io
export buildconfig_name=${imagestream_name}-build
oc create imagestream ${imagestream_name} --namespace=${namespace_name}

# create BuildConfig and build image
function process_manifest() {
  local manifest_name=$1
  local dir_path=${2:-$(cd $(dirname ${BASH_SOURCE[-1]}) && pwd)}

  envsubst < ${dir_path}/${manifest_name}.yaml.tpl > ${dir_path}/${manifest_name}.yaml
  oc apply --filename ${dir_path}/${manifest_name}.yaml --namespace=${namespace_name}
  rm ${dir_path}/${manifest_name}.yaml
}
process_manifest "build"
oc start-build  ${buildconfig_name} --namespace=${namespace_name} --from-dir=${root_dir} --no-cache --follow

# apply configmap to current and default namespaces
# this makes the agent available
oc process -f ${root_dir}/hack/agent-configmap-template.yaml | oc apply -f -
oc process -f ${root_dir}/hack/agent-configmap-template.yaml -n default | oc apply -f -
