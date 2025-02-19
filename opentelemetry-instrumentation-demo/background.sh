apt update
apt install -y openjdk-17-jdk openjdk-17-jre

docker pull grafana/k6:latest

cd /root/course/rolldice
chmod +x ./mvnw
chmod +x ./run.sh
./mvnw clean package -DskipTests

version=v2.6.0-beta.2
jar=opentelemetry-javaagent.jar
curl -sL https://github.com/grafana/grafana-opentelemetry-java/releases/download/${version}/grafana-opentelemetry-java.jar -o ${jar}