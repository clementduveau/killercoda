#!/usr/bin/env bash

echo "Building instance..."

# Create working directory and copy assets
mkdir -p /root/course
cp -r /root/assets/* /root/course/

# Move to working directory and start services
cd /root/course
docker-compose -f docker-compose.yaml up -d
git clone https://github.com/grafana/opentelemetry-workshop.git; mv opentelemetry-workshop/source/rolldice rolldice; rm -r opentelemetry-workshop

# Install JRE
apt update; apt install -y openjdk-17-jdk openjdk-17-jre;

clear; docker pas; echo "\n\n>> Environment ready!"
