#!/usr/bin/env bash

# Install JRE
apt update; apt install -y openjdk-17-jdk openjdk-17-jre;

# Pull k6 image for later
docker pull grafana/k6:latest;