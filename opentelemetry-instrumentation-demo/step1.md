# Explore the LGTM Stack

The LGTM (Loki, Grafana, Tempo, Mimir/Prometheus) stack provides a complete observability solution:
- **Loki**: Log aggregation system
- **Grafana**: Visualization and monitoring platform
- **Tempo**: Distributed tracing backend
- **Prometheus**: Metrics collection and storage

## Starting the Stack

The environment initialization script has already:
1. Installed Docker Compose plugin
2. Copied the necessary configuration files
3. Started the LGTM stack

You can verify the stack is running with:
```bash
docker-compose ps
```{{exec}}

All services should be in a healthy state (except permission-init). The stack includes:
- Grafana, accessible at [http://localhost:3000]({{TRAFFIC_HOST1_3000}})
- Prometheus
- Loki
- Tempo

## Verifying the Setup

1. Open Grafana at [http://localhost:3000]({{TRAFFIC_HOST1_3000}})
2. You'll be automatically logged in as admin
3. Navigate to Explore > Metrics/Logs/Traces to verify:
   - Prometheus is configured for metrics
   - Loki is configured for logs
   - Tempo is configured for traces

For now, it's empty. Don't worry, in the next step, we'll explore how to use these tools to monitor our demo application.
