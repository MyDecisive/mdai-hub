# GreptimeDB 

## Local (Kind) installation

### Stanadalone

In [values.yaml](./values.yaml) enable greptimedb-standalone:
```yaml
greptimedb-standalone:
  enabled: true
```
Make sure greptime-cluster is disabled:
```yaml
greptimedb-caluster:
  enabled: false
```

### Cluster

In [values.yaml](./values.yaml) enable greptimedb-cluster:
```yaml
greptimedb-cluster:
  enabled: true
```
Make sure greptime-standalone is disabled:
```yaml
greptimedb-standalone:
  enabled: false
```


## AWS EKS installation

### Stanadalone

For AWS EKS installation a few preparation steps are required.  
You need a S3 bucket for object storage and EBS volume for WAL.  

#### Storage
Assume, your S3 bucket is named
`mdai-greptime-object-storage`  

For EBS volume we strongly recommend volume auto provisioning, provided by EBS CSI driver, as it allows you do not think about availability zones matching.

In [values.yaml](./values.yaml) make sure, that persistence section is not commented out: 
```yaml
greptimedb-standalone:
  enabled: true
  persistence:
    storageClass: gp2
    selector:
      matchLabels:
        app: mdai-greptime
        env: mdai
    size: 20Gi
```  

#### <a id="standalone-aws-iam"></a>AWS IAM {#standalone-aws-iam}

For S3 bucket access create IAM policy `greptime-irsa-mdai-greptime` as follows (make sure bucket name is correct):  
```json
{
    "Statement": [
        {
            "Action": "s3:ListBucket",
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::mdai-greptime-object-storage",
            "Sid": "ListBucket"
        },
        {
            "Action": [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
                "s3:ListBucketMultipartUploads",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:AbortMultipartUpload"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::mdai-greptime-object-storage/*",
            "Sid": "ObjectRW"
        }
    ],
    "Version": "2012-10-17"
}
```
Attach this policy to IAM role `greptime-s3-mdai-greptime` with the following trust policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::168005146325:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/3B3EC4E13EF381458A69207C78AC56EC"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-2.amazonaws.com/id/3B3EC4E13EF381458A69207C78AC56EC:sub": "system:serviceaccount:mdai:greptimedb-standalone",
                    "oidc.eks.us-east-2.amazonaws.com/id/3B3EC4E13EF381458A69207C78AC56EC:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```  
where  
`168005146325` - aws account id  
`us-east-2` - aws region  
`3B3EC4E13EF381458A69207C78AC56EC` - EKS cluster OIDC provider ID  
`greptimedb-standalone` - proposed k8s ServiceAccount name for GreptimeDB  

In [values.yaml](./values.yaml) make sure that `serviceAccount` section is not commented out:   
```json
greptimedb-standalone:
  enabled: true
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::168005146325:role/greptime-irsa-mdai-greptime
    create: true
    name: greptimedb-standalone
```  
For the role arn in annotations and sa name add valid values




### Cluster

For AWS EKS installation a few preparation steps are required.  
You need a S3 bucket for object storage and EBS volumes for GreptimeDB WAL and etcd.  
For EBS volume we strongly recommend volume auto provisioning, provided by EBS CSI driver, as it allows you do not think about availability zones matching.  


#### Storage

Make sure `greptimedb-cluster.objectStorage`,  `greptimedb-cluster.persistence`, `greptimedb-cluster.serviceAccount` and `etcd.persistence` section is not commented out in [values.yaml](./values.yaml)  

```yaml
greptimedb-cluster:
  # AWS start
  objectStorage:
    s3:
      bucket: mdai-greptime-object-storage
      endpoint: s3.us-east-2.amazonaws.com
      region: us-east-2
      root: ""
  persistence:
    storageClass: gp2
    selector:
      matchLabels:
        app: mdai-greptime
        env: mdai
    size: 20Gi
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::168005146325:role/greptime-irsa-mdai-greptime-test
    create: true
    name: greptimedb-cluster
  # AWS end

etcd:
  # AWS start
  persistence:
    enabled: true
    storageClass: gp2
    accessModes:
      - ReadWriteOnce
    size: 8Gi
  # AWS end
 ```
 
 #### AWS IAM
 
 Needed steps described in [Standalone/AWS/IAM](#standalone-aws-iam) section.
 
 #### Install
 
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
