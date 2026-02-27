# GreptimeDB 



## Local (Kind) installation

For local install make sure all sections between
```AWS start``` and ```AWS end``` are commented out  

### Stanadalone

Run:  
```bash
helm upgrade --install --namespace mdai --create-namespace --cleanup-on-fail --devel  --set greptimedb-standalone.enabled=true mdai .
```  

### Cluster

Install GreptimeDb operator:  
```bash
helm repo add greptime https://greptimeteam.github.io/helm-charts/
helm repo update
helm upgrade \
  --install \
  --create-namespace \
  greptimedb-operator greptime/greptimedb-operator \
  -n mdai
```

Install MDAI with GreptimeDB:
```bash
helm upgrade --install mdai . -n mdai --set greptimedb-cluster.enabled=true
```  


## AWS EKS installation

Make sure all sections between
```AWS start``` and ```AWS end``` are NOT commented out

For AWS EKS installation S3 bucket and IAM role need to be created.    
[./terraform](./terraform) directory contains Terraform scripts that will create necessary aws resources.
Please refer to [README](./terraform/README.md) for details.  

Terraform script returns the following output variables values:  
```
bucket_arn = "arn:aws:s3:::mdai-greptime-object-storage"
bucket_name = "mdai-greptime-object-storage"
effective_aws_account_id = "168005146325"
iam_policy_arn = "arn:aws:iam::168005146325:policy/mdai-greptime-s3-policy"
iam_role_arn = "arn:aws:iam::168005146325:role/mdai-greptime-irsa-role"
```  


### Stanadalone

Use terraform variables (input & output) values in [values.yaml](./values.yaml):
```yaml
greptimedb-standalone:
  enabled: false
  ## AWS start
  objectStorage:
    s3:
      bucket: mdai-greptime-object-storage # <- bucket_name
      endpoint: s3.us-east-2.amazonaws.com # <- aws_region
      region: us-east-2 # <- aws_region
      root: ""
  persistence:
    storageClass: gp2
    size: 20Gi # <- bucket_size_gb
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::168005146325:role/mdai-greptime-irsa-role # <- iam_role_arn
    create: true
    name: greptimedb-standalone
## AWS end
```

### Install

Run:  
```bash
helm upgrade --install --namespace mdai --create-namespace --cleanup-on-fail --devel  --set greptimedb-standalone.enabled=true mdai .
```




### Cluster

Use terraform variables (input & output) values in [values.yaml](./values.yaml):  
```yaml
greptimedb-cluster:
  enabled: false
  meta:
    backendStorage:
      etcd:
        endpoints:
          - mdai-etcd.mdai.svc.cluster.local:2379
    readinessProbe:
      initialDelaySeconds: 40
## AWS start
  objectStorage:
    s3:
      bucket: mdai-greptime-object-storage # <- bucket_name
      endpoint: s3.us-east-2.amazonaws.com # <- aws_region
      region: us-east-2 # <- aws_region
      root: ""
  datanode:
    storage:
      storageClassName: gp2
      size: 20G # <- ibucket_size_gb
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::168005146325:role/greptime-irsa-mdai-greptime-test # <- iam_role_arn
      create: true
      name: greptimedb-cluster
## AWS end
```

 
### Install
 
Install GreptimeDb operator:  
```bash
helm repo add greptime https://greptimeteam.github.io/helm-charts/
helm repo update
helm upgrade \
  --install \
  --create-namespace \
  greptimedb-operator greptime/greptimedb-operator \
  -n mdai
```

Install MDAI with GreptimeDB:
```bash
helm upgrade --install mdai . -n mdai --set greptimedb-cluster.enabled=true
```
