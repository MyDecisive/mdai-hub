### Install MDAI with Tracealyzer
```bash
helm upgrade --install --namespace mdai --create-namespace \
  --cleanup-on-fail --devel \
  --values greptimedb-values.yaml \
  --values tracealyzer-values.yaml \
  --set greptimedb-standalone.enabled=true \
  --set mdai-tracealyzer.enabled=true \
  mdai .
```

### Install MDAI with Tracealyzer with MDAI Grafana dashboards
```bash
helm upgrade --install --namespace mdai --create-namespace \
--cleanup-on-fail --devel \
--values greptimedb-values.yaml \
--values tracealyzer-values.yaml \
--values grafana-values.yaml \ 
--set greptimedb-standalone.enabled=true \
--set mdai-tracealyzer.enabled=true \
mdai .
```