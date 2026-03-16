kubectl -n mdai create secret generic thanos-objstore-config --from-file=thanos.yaml=thanos_secret.yaml

helm upgrade --install thanos oci://registry-1.docker.io/bitnamicharts/thanos --version 17.3.1  --values thanos-values.yaml -n mdai
