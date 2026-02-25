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

### Cluster

WAL PV:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  labels:
    app: greptime-standalone
    env: mdai
  name: greptime-wal
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 20Gi
  csi:
    driver: ebs.csi.aws.com
    volumeHandle: vol-0049215b1cb36596d
  persistentVolumeReclaimPolicy: Retain
  storageClassName: greptime
  volumeMode: Filesystem
```

WAL PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/instance: mdai
    app.kubernetes.io/name: greptimedb-standalone
  name: data-mdai-greptimedb-standalone-0
  namespace: mdai
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  selector:
    matchLabels:
      app: greptime-standalone
      env: mdai
  storageClassName: greptime
  volumeMode: Filesystem
  volumeName: greptime-wal
```

IAM role (greptime-irsa-mdai-greptime-test):
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
Trust policy:
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

serviceaccount:
```yaml
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::168005146325:role/greptime-irsa-mdai-greptime-test
```    

statefulset:
```yaml
volumeClaimTemplates:
- apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    creationTimestamp: null
    name: data
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
    volumeMode: Filesystem 
```

helm:
```yaml
objectStorage:
  s3:
    bucket: mdai-greptime-object-storage
    endpoint: s3.us-east-2.amazonaws.com
    region: us-east-2
    root: ""
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::168005146325:role/greptime-irsa-mdai-greptime-test
  create: true
  name: greptimedb-standalone
```
