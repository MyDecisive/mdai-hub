# GreptimeDB 



## Local (Kind) installation

For local install make sure all sections between
```AWS start``` and ```AWS end``` are commented out  

### Stanadalone

Run:  
```bash
helm upgrade \
  --install \
  --namespace mdai \
  --create-namespace \
  --cleanup-on-fail \
  --devel \ 
  --values greptimedb-values.yaml \
  --set greptimedb-standalone.enabled=true mdai .
```  


## AWS EKS installation

Make sure all sections between
```AWS start``` and ```AWS end``` are NOT commented out

For AWS EKS installation S3 bucket and IAM role need to be created.    
[./greptimedb/terraform](./greptimedb/terraform) directory contains Terraform scripts that will create necessary aws resources.
Please refer to [README](./greptimedb/terraform/README.md) for details.  

Terraform script returns the following output variables values:  
```
bucket_arn = "arn:aws:s3:::mdai-greptime-object-storage"
bucket_name = "mdai-greptime-object-storage"
effective_aws_account_id = "123456789012"
iam_policy_arn = "arn:aws:iam::123456789012:policy/mdai-greptime-s3-policy"
iam_role_arn = "arn:aws:iam::123456789012:role/mdai-greptime-irsa-role"
```  


### Stanadalone

Use terraform variables (input & output) values in [values.greptimedb.yaml](./values.greptimedb.yaml):
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
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/mdai-greptime-irsa-role # <- iam_role_arn
    create: true
    name: greptimedb-standalone
## AWS end
```

### Install

Run:  
```bash
helm upgrade --install --namespace mdai --create-namespace --cleanup-on-fail --devel  --set greptimedb-standalone.enabled=true mdai .
```
