# Explore the setup

The foreground script will bring up a minimal monitoring stack (Prometheus 3, node_exporter) using Docker Compose.

Once it's running, you will have metrics coming into Prometheus. Wait a few minutes to see more historical data.

You can explore Prometheus on [port 9090]({{TRAFFIC_HOST1_9090}}) and Node Exporter on [port 9100]({{TRAFFIC_HOST1_9100}})

## Prometheus 3 new features

- New UI
- Native histograms support (not enabled in this lab)
- OTel Compatibility (not enabled in this lab)
- UTF-8 support (enabled but not used)
- Remote write 2.0 (enabled but not used)