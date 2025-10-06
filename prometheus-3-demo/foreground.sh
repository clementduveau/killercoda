#!/usr/bin/env bash

echo "Starting Prometheus and Node Exporter..."

cd /prometheus
docker-compose -f docker-compose.yaml up -d

# Wait for services to be healthy
echo "Waiting for Prometheus to be ready."
until docker container inspect prometheus 2>/dev/null | grep -q '"Status": "healthy"'; do
  printf "."
  sleep 2
done

echo -e "\e[32m✓\e[0m Prometheus 3 is ready !"