# Metrics

This guide refers to the platform usage app, setup instructions for that app can be found [here](platform_usage_app_setup.md) and the actual source can be found [here](../../../examples/k8s/platform-usage). 

## Prometheus

The sample app exposes metrics using Spring Boot Actuator, then sends metrics to Prometheus using a CustomResourceDefinition (CRD) called `ServiceMonitor`. When the Prometheus operator is deployed on the platform, it creates 4 CRDs: `Prometheus`, `ServiceMonitor`, `PrometheusRule`, and `Alertmanager`.

To expose Prometheus metrics using Spring Boot Actuator, make sure the following lines are in `build.gradle` and `application.properties`.

`build.gradle`:
```gradle
dependencies {
  compile("org.springframework.boot:spring-boot-starter-actuator")
  compile("io.micrometer:micrometer-registry-prometheus")
}
```

`application.properties`:
```ini
management.endpoints.web.exposure.include=prometheus
```

This will create a Prometheus metric endpoint. To see the endpoint, run the app and go to https://sample.gsp.test/actuator/prometheus.

To send the metrics to Prometheus, you need to create a `ServiceMonitor` for your service.

```yml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: platform-usage
  labels:
    release: gsp-prometheus		# important
spec:
  selector:
    matchLabels:
      app: platform-usage 		# must match the label of the app service
  endpoints:
    - port: http
      interval: 5s
      path: '/actuator/prometheus'	# path to metrics
```
Make sure that the metadata labels include `release: gsp-prometheus` because that is the label that Prometheus will search for to find services it needs to monitor. Also be careful to include the label of your app in `matchLabels` because that is how the ServiceMonitor will find your service. You can specify whatever endpoints you want. In this case, we only have one exposed port named `http`, so that is the only port we specify.