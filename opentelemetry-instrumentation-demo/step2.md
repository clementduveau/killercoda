# Install Grafana Alloy (OpenTelemetry Distribution)

First, we need an OpenTelemetry Collector. In this tutorial, we will use Grafana Alloy, an alternative distribution from Grafana. It has been started with your stack.

Check Alloy current configuration [on port 12345]({{TRAFFIC_HOST1_12345}}). Go to Graph tab to better understand what is happening.

## Explanations

Our Alloy has a single pipeline: it gets metrics (about itself), do some processing to enrich or filter the data, and then it writes them to Prometheus.

This behavior, and the fact that you can route metrics/logs/traces in different process and different backend is at the heart of the OpenTelemetry Collector.

Our Alloy will be the gateway to all the signals and processing of those signals. So let's configure it to accept metrics, logs and traces through OpenTelemetry Line Protocol and push them to the backends.

## Configure our OpenTelemetry pipelines

Let's modify our config file at `/course/custom-config.alloy`

We will **add** the following content:

```
declare "pipeline" {
    otelcol.receiver.otlp "default" {
        // configures the default grpc endpoint "0.0.0.0:4317"
        grpc { }
        // configures the default http/protobuf endpoint "0.0.0.0:4318"
        http { }

        output {
            metrics = [otelcol.processor.resourcedetection.default.input]
            logs    = [otelcol.processor.resourcedetection.default.input]
            traces  = [otelcol.processor.resourcedetection.default.input]
        }
    }

    otelcol.processor.resourcedetection "default" {
        detectors = ["env", "system"] // add "gcp", "ec2", "ecs", "elastic_beanstalk", "eks", "lambda", "azure", "aks", "consul", "heroku"  if you want to use cloud resource detection

        system {
            hostname_sources = ["os"]
        }

        output {
            metrics = [otelcol.processor.transform.add_resource_attributes_as_metric_attributes.input]
            logs    = [otelcol.processor.batch.default.input]
            traces  = [
                otelcol.processor.batch.default.input,
                otelcol.connector.host_info.default.input,
            ]
        }
    }

    otelcol.connector.host_info "default" {
        host_identifiers = ["host.name"]

        output {
            metrics = [otelcol.processor.batch.default.input]
        }
    }

    otelcol.processor.transform "add_resource_attributes_as_metric_attributes" {
        error_mode = "ignore"

        metric_statements {
            context    = "datapoint"
            statements = [
                "set(attributes[\"deployment.environment\"], resource.attributes[\"deployment.environment\"])",
                "set(attributes[\"service.version\"], resource.attributes[\"service.version\"])",
            ]
        }

        output {
            metrics = [otelcol.processor.batch.default.input]
        }
    }

    otelcol.processor.batch "default" {
        output {
            metrics = [otelcol.exporter.prometheus.metrics.input]
            logs    = [otelcol.exporter.otlphttp.logs.input]
            traces  = [otelcol.exporter.otlphttp.traces.input]
        }
    }

    otelcol.exporter.prometheus "metrics" {
        forward_to = prometheus.remote_write.metrics_service.receiver
    }

    otelcol.exporter.otlphttp "logs" {
        client {
            endpoint = "http://loki:3100/otlp"
        }
    }

    otelcol.exporter.otlphttp "traces" {
        client {
            endpoint = "http://tempo/v1/traces"
        }
    }

    prometheus.remote_write "metrics_service" {
        endpoint {
            url = "http://prometheus:9090/api/v1/write"
        }
    }
}
```{{copy}}

> You don't need to restart Alloy in this environment. It is hot-reloading Alloy's config. If you don't see it change on [Alloy's interface]({{TRAFFIC_HOST1_12345}}), then you can restart the container with:
> ```
> docker restart alloy
> ```

## Conclusion

Alloy is ready to receive telemetry data through the OpenTelemetry protocol (OTLP) on ports:
- 4317 for gRPC
- 4318 for HTTP/protobuf
and it will forward them to Prometheus, Loki and Tempo.

We are not doing a lot of processing or filtering here as it is an example. Feel free to come back after the next step to try to change your pipelines.