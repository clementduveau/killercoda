#!/usr/bin/env bash

echo "Building instance..."

# Move to working directory and start services
cd /root/course
docker-compose -f docker-compose.yaml up -d
git clone https://github.com/grafana/opentelemetry-workshop.git; mv opentelemetry-workshop/source/rolldice rolldice; rm -r opentelemetry-workshop

clear; docker ps; echo ">> Environment ready!"
