# Install Grafana Alloy (OpenTelemetry Distribution)

First, we need an OpenTelemetry Collector. In this tutorial, we will use Grafana Alloy, an alternative distribution from Grafana. It has been started with your stack.

Check Alloy's current configuration [on port 12345]({{TRAFFIC_HOST1_12345}}). Go to the Graph tab to better understand what is happening.

## Explanations

Our Alloy has a single and simple pipeline:
- Alloy starts a Prometheus exporter to expose metrics (about itself in this case)
- A discovery component is used to find where the exporter is located. It also adds some metadata to the metrics when scraped
- A scrape job to periodically get the metrics from the targets listed in the discovery component
- A relabel job to filter out some metrics that we don't want (more exactly, keep only the ones we want in this case)
- A remote-write component to send those metrics to Prometheus

Alloy will be the gateway for all signals and their processing. Let's configure it to accept metrics, logs, and traces through **OpenTelemetry Line Protocol** and push them to our backends.

## Configure our OpenTelemetry pipelines

Let's modify our config file at `~/course/config.alloy`

Replace the current configuration with the following content:

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
        endpoint = "http://tempo:4318"
    }
}

prometheus.remote_write "metrics_service" {
    endpoint {
        url = "http://prometheus:9090/api/v1/write"
    }
}
```{{copy}}

You can also find this configuration under `~/course/opentelemetry.alloy`

Restart Alloy to apply your changes:

```bash
docker restart alloy
```{{exec}}

Check that your pipelines are up in [Alloy]({{TRAFFIC_HOST1_12345}})

## Understanding the Pipeline

This graph is more complex than before. Here's what's happening:

1. **OTLP Receiver**: Listens for OTLP messages (logs, metrics, and traces)
2. **Resource Detection**: Enriches data with host metadata (e.g., hostname) that the app might not be aware of. From here, each signal follows a different path:
   - **Metrics Pipeline**:
     - Processor: to add metadata
     - Then sent to batch processor
   - **Logs Pipeline**: 
     - Directly sent to batch processor
   - **Traces Pipeline**: Split into two streams:
     - Sent to batch processor for backend storage
     - Sent to host info to generate usage metrics

3. **Batch Processor**: 
   - Groups messages to optimize network usage
   - Routes signals to appropriate backends:
     - Metrics → Prometheus
     - Logs → Loki
     - Traces → Tempo

4. **Backend Communication**:
   - OTLPHTTP: Sends data to OpenTelemetry-compatible APIs
   - Prometheus Exporter: Converts metrics to Prometheus format
   - Remote Write: Sends metrics to Prometheus

> Note: Mimir is 100% compatible with Prometheus, scalable, and accepts OpenTelemetry natively. Using Mimir would eliminate the need for the Prometheus exporter.

## Conclusion

Alloy is now configured to:
- Receive telemetry data via OTLP protocol on:
  - Port 4317 (gRPC)
  - Port 4318 (HTTP/protobuf)
- Enrich the data with host metadata
- Forward processed data to Prometheus, Loki, and Tempo

Let's proceed to instrument our application.
