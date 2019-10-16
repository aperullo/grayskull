## Persistent File Storage

All of your storage based on volumes is automatically distributed and persisted by services in the *grayskull-storage* namespace. To create a persistent volume for your application, add a `PersistentStorageClaim` to your manifest.

```
---
# Claim an amount of space
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  ...
  template:
    spec:
      containers:
        ...
        # mount the declared volume
        volumeMounts:
        - name: my-app-persistent-storage
          mountPath: /var/data

      # Declare the claim as a volume.
      volumes:
      - name: my-app-persistent-storage
        persistentVolumeClaim:
          claimName: my-app-claim
```

## S3/Object storage

You can have the *grayskull-storage* service provision S3 compatible storage for your application. Have an administrator prepare an object user for your team or application (TODO: also a bucket?). They will tell you where your app can consume the `accesskey` and `secretkey` secrets for authenticating with the S3 storage. Using that user's credentials, your app can now create buckets, upload/download objects, etc.

## Platform usage example app

This guide refers to the platform usage app, setup instructions for that app can be found [here](platform_usage_app_setup.md) and the actual source can be found [here](../../../examples/k8s/platform-usage). 

## Rook Ceph

To use the Rook Ceph storage, we need a `PersistentVolumeClaim`, and we also need a `volumes` and a `volumeMounts` section in the `Deployment` for the database. We will use Redis as an example database that requires persistence.

`sample.yml`:
```yml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: redis-dplymnt
    labels:
      app: redis
spec:
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis
          volumeMounts:
          - mountPath: /data
            name: redis-store   # name of volume declared below
          ports:
          - containerPort: 6379
      volumes:
        - name: redis-store
          persistentVolumeClaim:
            claimName: redis-pvc  # name of PersistentVolumeClaim

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  labels:
    app: redis
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 30Mi     # size of storage needed
```
