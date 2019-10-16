# Logging

This guide refers to the platform usage app, setup instructions for that app can be found [here](platform_usage_app_setup.md) and the actual source can be found [here](../../../examples/k8s/platform-usage).

## ELK

For logging, we use `logstash-logback-encoder` to send logs to Logstash, which then sends the logs to Elasticsearch, which Kibana then picks up on automatically.

To use `logstash-logback-encoder`, make sure the following dependencies are in `build.gradle`.

```gradle
dependencies {
  compile("net.logstash.logback:logstash-logback-encoder:5.3")
  compile("ch.qos.logback:logback-classic:1.2.3")
}
```

To configure the loggers, you need a `logback-spring.xml` file. In that file, create an appender for every location you want to send logs. In our example, we have 3 appenders, one for sending logs to stdout, one for saving logs in files, and one for sending logs to Logstash.

If you just want to send logs to Logstash, make sure the following is in `logback-spring.xml`:

```xml
<appender name="STASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>${LOGSTASH_HOST}</destination>
    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <customFields>{"app_name":"logging-sample"}</customFields>
    </encoder>
</appender>

<logger name="${LOGGER_NAME}" level="${LOGGER_LEVEL:-DEBUG}" additivity="false">
    <appender-ref ref="STASH" />
</logger>
```

The logger name should be the name of the package of the logger(s). In this case, the package name is `acc` and is set in `application.properties`.

The Logstash Logback encoder needs to know the location of the Logstash host in order to send logs to it. In our app, we set the location in `application.properties` and read it in to `logback-spring.xml`. The location of the Logstash host in the Kubernetes cluster is `gsp-logstash.grayskull-logs:1514`. However, if the application is in the same namespace as the Logstash host, the namespace can be omitted to become `gsp-logstash:1514`.

You can read properties from `application.properties` into `logback-spring.xml` by using the `springProperty` tag.

`application.properties`:
```ini
logstash.host=gsp-logstash:1514
logger.name=acc
```
`logback-spring.xml`:

```xml
<springProperty name="LOGSTASH_HOST" source="logstash.host"/>
<springProperty name="LOGGER_NAME" source="logger.name"/>
```

The Logstash service that is used on the platform is configured to name logs based on a `customField` called `app_name`, so be sure to add that custom field to any logger that sends logs to Logstash. This way, logs will be indexed with whatever your `app_name` is set as. For the sample app, the logs are prefixed with `logging-sample-`. If no `app_name` is set, the logs will default to being prefixed with `logstash-`.
 

