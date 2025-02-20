#!/bin/bash

printf "Starting monitoring infrastructure...\n"

cd /root/course/lgtm
docker-compose -f docker-compose.yaml up -d

# Wait for critical services to be healthy
printf "\nWaiting for Grafana to be ready..."
until docker container inspect grafana 2>/dev/null | grep -q '"Status": "healthy"'; do
  printf "."
  sleep 2
done

printf "\n\n>> Monitoring infrastructure is ready!\n"
printf ">> Additional components are being set up in the background...\n\n"
