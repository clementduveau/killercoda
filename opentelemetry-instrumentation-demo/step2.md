# Install Grafana Alloy (OpenTelemetry Distribution)

First, we need an OpenTelemetry Collector. In this tutorial, we will use Grafana Alloy, an alternative distribution from Grafana. It has been started with your stack.

Check Alloy current configuration [on port 12345]({{TRAFFIC_HOST1_12345}}). Go to Graph tab to better understand what is happening.

## Explanations

Our Alloy has a single and simple pipeline:
- Alloy starts a Prometheus exporter to expose metrics (about iself in this case).
- A discovery component is used to find were is the exporter located. It also add some metadata to the metrics when scraped.
- A scrape job to periodically get the metrics from the targets listed in the discovery component.
- A relabel job to filter out some metrics that we don't want (more exactly keep only the one we want in this case)
- A remote-write component to send those metrics to Prometheus.

Alloy will be the gateway to all the signals and processing of those signals. So let's configure it to accept metrics, logs and traces through **OpenTelemetry Line Protocol** and push them to our backends.

## Configure our OpenTelemetry pipelines

Let's modify our config file at `/course/config.alloy`

We will change the config file for the following content:

```
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
    forward_to = [prometheus.remote_write.metrics_service.receiver]
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
```{{copy}}

You can also find it under `~/course/opentelemetry.alloy`

Restart Alloy to apply your changes:

```bash
docker restart alloy
 ```{{exec}}
```
Check that your pipelines are up in [Alloy]({{TRAFFIC_HOST1_12345}})

This graph is a bit more complex. What is happening ?
- OTLP receiver: It listens for OTLP messages (could be logs, metrics and traces)
- Resource Detection: It enrichs data with metadata about the host itself. Like the hostname. Something the app is probably never aware of. From there, each signal follow a different path:
    - Metrics:
        - First, they go to a processor to get selected enrichment. We don't want to add all metadata as labels, it would impair Prometheus performance.
        - Then they are sent to the batch processor.
    - Logs: They are send to the batch processor directly.
    - Traces: they are duplicated and sent to 2 components:
        - Batch processor, to be send to the backends
        - Host info: to generates usage metrics. Those metrics are sent to the batch processor
- Batch processor: It groups messages together to optimize network (1 big HTTP request has less overhead than 1000 small ones). It also routes the signals to the right backends. (Logs to Loki, traces to Tempo...)
- OTLPHTTP: Send to an OpenTelemetry-compatible API on HTTP (OTLP also supports gRPC hence the suffix `HTTP`)
- OpenTelemetry Exporter Prometheus: Prometheus doesn't accept OTLP so we need to convert the metrics to Prometheus format with this component.
- Remote write to send metrics to Prometheus

> Mimir is 100% compatible with Prometheus, scalable and accepts OpenTelemetry. We would not need the exporter with it.

## Conclusion

Alloy is ready to receive telemetry data through the OpenTelemetry protocol (OTLP) on ports:
- 4317 for gRPC
- 4318 for HTTP/protobuf
and it will enrich the data before forwarding it to Prometheus, Loki and Tempo.

Let's instrument our app now.