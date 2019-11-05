#! /usr/bin/env bash

this_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
root_dir=$(dirname ${this_dir})

export build_namespace_name=${1:-vault-ns}
export agent_namespace_name=${2:-vault-ns}

export imagestream_name=jenkins-vault-agent
export buildconfig_name=${imagestream_name}-build
export build_pull_secret_name=registry-redhat-io
oc create imagestream ${imagestream_name} --namespace=${build_namespace_name}

# create BuildConfig and build image
function process_manifest() {
  local manifest_name=$1
  local dir_path=${2:-$(cd $(dirname ${BASH_SOURCE[-1]}) && pwd)}

  envsubst < ${dir_path}/${manifest_name}.yaml.tpl > ${dir_path}/${manifest_name}.yaml
  oc apply --filename ${dir_path}/${manifest_name}.yaml --namespace=${build_namespace_name}
  rm ${dir_path}/${manifest_name}.yaml
}
pull_secret_name=${build_pull_secret_name} process_manifest "build"
oc start-build  ${buildconfig_name} --namespace=${build_namespace_name} --from-dir=${root_dir} --no-cache --follow

# apply configmap to current and default namespaces
# this makes the agent available
oc process -f ${root_dir}/hack/agent-configmap-template.yaml \
  -p IMAGE_URL=image-registry.openshift-image-registry.svc:5000/${build_namespace_name}/${imagestream_name} \
  -p IMAGE_PULL_SECRET=openshift-internal-registry | \
    oc apply --namespace ${agent_namespace_name} -f -
