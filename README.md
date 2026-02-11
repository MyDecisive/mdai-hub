# MDAI Hub

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/mdai-hub)](https://artifacthub.io/packages/search?repo=mdai-hub)

This is the official Helm chart for [MyDecisive.ai](https://www.mydecisive.ai/), an open-core solution for monitoring and managing OpenTelemetry pipelines on Kubernetes.

_After initial checkout, switching branches or modifying `Chart.yaml`, run `helm dependency update . --repository-config /dev/null`_

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+
- [cert-manager](https://cert-manager.io/docs/) [optional](#disable-cert-manager)

## Install MDAI Hub helm chart

```bash
helm upgrade --install \
  mdai oci://ghcr.io/mydecisive/mdai-hub \
  --namespace mdai \
  --create-namespace \
  --cleanup-on-fail \
  --devel
```

Use additional `grafana-values.yaml` to deploy Grafana with MDAI dashboards to your cluster.

## Disable cert-manager

Amend `values.yaml` as follows.

```yaml
opentelemetry-operator:
  enabled: true
  admissionWebhooks:
    certManager:
      enabled: false # <= set to false
    autoGenerateCert:
      enabled: true # <= set to true
      recreate: true # <= set to true for regenerating certs upon each deploy
      certPeriodDays: 365 # <= cert validity period
```

```yaml
mdai-operator:
  enabled: true
  admissionWebhooks:
    certManager:
      enabled: false # <= set to false
      issuerRef: {}
      certificateAnnotations: {}
      issuerAnnotations: {}
      duration: ""
      renewBefore: ""
    autoGenerateCert:
      enabled: true # <= set to true
      recreate: true # <= set to true for regenerating certs upon each deploy
      certPeriodDays: 365 # <= cert validity period
```

## Learn more

- Visit our [solutions page](https://www.mydecisive.ai/solutions) for more details MyDecisive's approach to composable observability.
- Head to our [docs](https://docs.mydecisive.ai/) to learn more about MyDecisive's tech.

## Info and Support

Please contact us via our Community Slack channels

- [#mdai-community-discussion](https://mydecisivecommunity.slack.com/archives/C08LE3DJ877) - All discussion
- [#mdai-docs-questions](https://mydecisivecommunity.slack.com/archives/C090KU6F679) - Questions about docs
- [#mdai-feature-requests](https://mydecisivecommunity.slack.com/archives/C090UH3JYNS) - Raising a request for new capabilities
- [#mdai-platform-support](https://mydecisivecommunity.slack.com/archives/C090KU1MB6K) - Assistance with using MDAI
