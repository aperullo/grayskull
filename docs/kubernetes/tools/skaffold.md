# Skaffold

Skaffold is a developer tool to ease developing kubernetes native applications.
It can watch a project, build changes and deploy them to a cluster. 
It can also automatically forward local ports to your application running in k8s for ease of testing/debugging.

## Prereqs

* Install [Skaffold](https://skaffold.dev/docs/install/)
* Working kubeconfig / kubectl

## Instructions

Create a skaffold config file in your project called `skaffold.yaml`

```yaml
apiVersion: skaffold/v2alpha2
kind: Config
build:
  artifacts:
    - image: <image_registry>/<image_repo> # No tag name is needed, it will automatically be generated
      context: ./ # Directory to pass to docker build
  local: {} # Specifies using local docker builder
deploy:
  kubectl:
    # Can use manifests or helm charts
    manifests:
      - ./k8s/*.yaml
```

Run `skaffold dev --port-forward`

Any changes you make will rebuild your image and redeploy the app
