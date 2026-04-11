# Persistent Storage

## Prometheus

Prometheus operator does not allow to specify an existing PVC, so make sure you PV satisfied a Prometheus PVC requirements
In order to enable persistent storage for Prometheus, uncomment the following block in 
Prometheus section (`kubeprometheusstack.prometheus.prometheusSpec`) of [values.yaml](./values.yaml):

```yaml
      ## uncomment below block to enable persistent storage
      ## BEGIN: persistent storage block
      #nodeSelector:
      #  topology.kubernetes.io/zone: us-east-1a
      #securityContext:
      #  fsGroup: 65534
      #  runAsGroup: 65534
      #  runAsNonRoot: true
      #  runAsUser: 65534
      #initContainers:
      #- name: prometheus-data-permission-setup
      #  image: busybox
      #  securityContext:
      #    runAsGroup: 0
      #    runAsNonRoot: false
      #    runAsUser: 0
      #  command: ["/bin/chown","-R","65534:65534","/prometheus"]
      #  volumeMounts:
      #  - name: prometheus-kube-prometheus-stack-prometheus-db
      #    mountPath: /prometheus
      #storageSpec:
      #  volumeClaimTemplate:
      #    spec:
      #      storageClassName: gp2
      #      accessModes: ["ReadWriteOnce"]
      #      volumeName: pv-prometheus
      #      resources:
      #        requests:
      #          storage: 10Gi
      ## END: persistent storage block  
```
With `securityContext` section we set `uid/guid` Prometheus instance will be running with.

With `InitContainers` section we set add `initContainer`, that fixes permissions for `/prometheus` mount point.

Please refer to the  original `kube-prometheus-stack` [values.yaml](https://github.com/prometheus-community/helm-charts/blob/65b61ef0c2ac8eca52d9b69aca3df8541f6ceb6f/charts/kube-prometheus-stack/values.yaml#L4134)
for more `storageSpec` details

## Valkey

In order to enable persistent storage for Valkey, do the following:
- uncomment the following lines in the Valkey block (`valkey.primary`) [values.yaml](./values.yaml):
```yaml
    ## uncomment below block to enable persistent storage
    ## BEGIN: persistent storage block
    #nodeSelector:
    #  topology.kubernetes.io/zone: us-east-1a
    #initContainers:
    #- command:
    #  - /bin/chown
    #  - -R
    #  - 1001:1001
    #  - /data
    #  image: busybox
    #  name: valkey-data-permission-setup
    #  securityContext:
    #    runAsGroup: 0
    #    runAsNonRoot: false
    #    runAsUser: 0
    #  volumeMounts:
    #  - mountPath: /data
    #    name: valkey-data
    ## END: persistent storage block    
    replicaCount: 1
    persistence:
      enabled: false
      ## uncomment below block to enable persistent storage
      ## BEGIN: persistent storage block
      #enabled: true
      #size: 10Gi
      #existingClaim: pvc-valkey
      ## END: persistent storage block    
```
- change `valkey.primary.persistence` to `true` in  [values.yaml](./values.yaml):
```yaml
    persistence:
      # set to true to enable persistent storage
      enabled: false
```

## NATS

### Kind

1. Enable creation PersistentVolumes in [values.yaml](./values.yaml) with `platform` equal `kind` and provide a path to your local directory.
```yaml
persistentStorage:
  nats:
    pv:
      # Specifies whether a PersistentVolumes should be created
      create: true
      # Deployment platform: can be either "aws" or "kind" (for local development))
      platform: kind
      # directory where data will be stored if deployment platform is "kind"
      localPath: "/tmp/mdai-data"
```
See comments in the file for more details.

2. Update [values.yaml](./values.yaml) as follows (see comments within the file itself):
```yaml
      fileStore:
        enabled: true
          dir: "/data/jetstream"
          pvc:
            enabled: true
            storageClassName: "mdai"  # should match PV's value
            size: 1Gi # should match PV's value
```
3 PVCs will be created

### AWS
Prerequisites:
[AWS EBS CSI driver](https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/) must be installed on the cluster


##### Static provisioning
1. Enable creation PersistentVolumes in [values.yaml](./values.yaml) with `platform` equal `kind` and providing a path to your local directory.
```yaml
persistentStorage:
  nats:
    pv:
      # Specifies whether a PersistentVolumes should be created
      create: true
      # Deployment platform: can be either "aws" or "kind" (for local development))
      platform: kind
      # directory where data will be stored if deployment platform is "kind"
      localPath: "/tmp/mdai-data"
```
See comments in the file for details.
1. On AWS create 3 EBS volumes of the desired size. Preferably these volumes should reside in different availability zones (but only in those, your EKS cluster run on)
2. Enable creation PersistentVolumes in [values.yaml](./values.yaml) with `platform` equal `aws` and provide other volume details as per comments in the file.
```yaml
persistentStorage:
  nats:
    pv:
      # Specifies whether a PersistentVolumes should be created
      create: true
      # Deployment platform: can be either "aws" or "kind" (for local development))
      platform: aws
      # directory where data will be stored if deployment platform is "kind"
      localPath: "/tmp/mdai-data"
      # shoudl match the storageClass of the PersistentVolumeClaims
      storageClass: mdai
      size: 1Gi
      # id - is AWS id of EBS volume
      # az - is AWS availability zone
      volumes:
        - id: vol-1
          az: us-east-1a
        - id: vol-2
          az: us-east-1b
        - id: vol-3
          az: us-east-1c
```          
See comments in the file for details.

3. Update [values.yaml](./values.yaml) as follows (see comments in the file itself as well):
```yaml
      fileStore:
        enabled: true
          dir: "/data/jetstream"
          pvc:
            enabled: true
            storageClassName: "mdai"  # should match PV value
            size: 1Gi # should match PV value
```

##### Dynamic provisioning
Update [values.yaml](./values.yaml) as follows (see comments in the file itself as well):
```yaml
      fileStore:
        enabled: true
          dir: "/data/jetstream"
          pvc:
            enabled: true
            storageClassName: "mdai"
            size: 1Gi # desired size
```
PersistentVolumeClaims will be created and CSI driver will do the rest - provision volumes, create PersistentVolume resources
