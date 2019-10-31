#! /usr/bin/env bash

pipeline_name=vault-agent-test-pipeline

function cleanup {
  oc delete buildconfig/${pipeline_name}
}
trap cleanup EXIT ERR

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: vault-agent-test-pipeline
spec:
  source:
    type: None
  strategy:
    type: JenkinsPipeline
    jenkinsPipelineStrategy:
      jenkinsfile: |
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
EOF

build_name=$(oc start-build ${pipeline_name} --output=name)

timeout_in_seconds=60
seconds_now=$(date +%s)
seconds_deadline=$(( $seconds_now + ${timeout_in_seconds} ))

build_phase=""
while [[ ${build_phase} != "Complete" ]]; do
  if [[ $(date +%s) -gt ${seconds_deadline} ]]; then
    echo "[FAIL] Timed out waiting for pipeline to run."
    break
  fi

  build_phase=$(oc get ${build_name} --output=jsonpath='{.status.phase}')
  case "${build_phase}" in
    # "New", "Pending", "Running", "Complete", "Failed", "Error", and "Cancelled"
    Complete)
      break
      ;;
    New|Pending|Running)
      echo "Waiting for pipeline with agent to complete, current phase is ${build_phase}."
      continue
      ;;
    Failed|Error|Cancelled)
      echo "[FAIL] Pipeline build using agent did not complete successfully."
      oc logs ${build_name}
      break
      ;;
    *)
      echo "[FAIL] Unexpected build phase: ${build_phase}"
      break
      ;;
  esac
done
if [[ ${build_phase} == "Complete" ]]; then
  echo "[PASS] Successfully ran test pipeline using agent"
else
  echo "[FAIL] Test pipeline failed at phase ${build_phase}".
fi
