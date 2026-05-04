```bash
helm upgrade --install --namespace mdai --create-namespace \
  --cleanup-on-fail --devel \
  --values greptimedb-values.yaml \
  --values tracealyzer-values.yaml \
  --set greptimedb-standalone.enabled=true \
  --set mdai-tracealyzer.enabled=true \
  mdai .
```