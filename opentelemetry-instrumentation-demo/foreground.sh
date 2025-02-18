#!/usr/bin/env bash

echo "Building instance..."

# Move to working directory and start services
cd /root/course
docker-compose -f docker-compose.yaml up -d
mv opentelemetry-workshop/source/rolldice rolldice; rm -r opentelemetry-workshop

clear; docker ps; echo ">> Environment ready!"
