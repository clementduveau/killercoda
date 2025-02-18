#!/usr/bin/env bash

# Install JRE
apt update; apt install -y openjdk-17-jdk openjdk-17-jre;

# Pull k6 image for later
docker pull grafana/k6:latest;

# Prepare Java
cd /root/course/rolldice;
./mvnw clean package -DskipTests;
version=v2.6.0-beta.2;
jar=opentelemetry-javaagent.jar;
if [[ ! -f ./${jar} ]] ; then
    curl -sL https://github.com/grafana/grafana-opentelemetry-java/releases/download/${version}/grafana-opentelemetry-java.jar -o ${jar};
fi