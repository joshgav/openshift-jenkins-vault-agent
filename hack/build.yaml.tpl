apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: ${buildconfig_name}
  namespace: ${namespace_name}
spec:
  runPolicy: Serial
  source:
    type: Binary
    binary: {}
    contextDir: .
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
      imageOptimizationPolicy: SkipLayers
      pullSecret:
        name: ${pull_secret_name}
  output:
    to:
      kind: ImageStreamTag
      name: ${imagestream_name}:latest
  triggers: []
  nodeSelector: {}
status:
  lastVersion: 0
