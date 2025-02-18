#!/usr/bin/env bash

printf "Building instance..."

# Move to working directory and start services
cd /root/course;
docker-compose -f docker-compose.yaml up -d;

docker ps; printf "\n\n\n>> Environment ready!\n\n\n";
