#!/usr/bin/env bash

echo "Building instance...";

# Clean up the environment
# mv /root/course/opentelemetry-workshop/source/rolldice /root/course/rolldice; rm -r opentelemetry-workshop;

# Move to working directory and start services
cd /root/course;
docker-compose -f docker-compose.yaml up -d;

docker ps; echo ">> Environment ready!";
