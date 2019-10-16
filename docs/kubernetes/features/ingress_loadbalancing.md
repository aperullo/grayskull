# Ingress/Loadbalancing

### What is an ingress?

An ingress is a special object that tells K8s to expose your application to the outside world behind a certain hostname. The ingress objects are picked up by the Ingress controller which routes outside requests by hostname, to the service they are assigned to. It also does load balancing between the running instances of your application.

A request sent to `my-app.mydomain.com` will first be directed to the ingress-controller, which will see if any ingress objects have the subdomain `my-app`. If one does, it gets routed to the service the ingress object specifies, the service acts as a single entry point for all deployments/sets of a given type. It therefore handles load balancing too. From the service, it gets directed to one of the pods in the deployment associated with that service.

### Assigning an ingress

Add an ingress object (like the one below) to your manifest to expose it to the outside world. The main things to specify are the `host`, the `serviceName`, and `servicePort` to direct traffic too.

```
...
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: <my-app>
  namespace: <my-app-namespace>
  labels:
      app: <my-app>
spec:
  rules:
  - host: <my-app.domain.com>
    http:
      paths:
      - backend:
          serviceName: <my-app-service>
          servicePort: <my-app-port>  # Can either be a named port or simply the number of the port
---
...

```

For advanced info on configuring ingress objects, see [the kubernetes ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#).