printf "Building instance..."

cd /root/course/lgtm
docker-compose -f docker-compose.yaml up -d

docker ps
printf "\n\n\n>> Environment ready!\n\n\n"
