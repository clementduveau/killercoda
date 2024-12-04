# Install the app

Our app is called "Rolldice". It's a dummy Java app that we will instrument. It's available in the `course` folder. We will install it.

> The rolldice app comes from the [OpenTelemetry Workshop repo from Grafana Labs](https://github.com/grafana/opentelemetry-workshop) and may be updated outside of this repo.

1. Install Java Runtime

   ```bash
   apt update && apt install -y openjdk-17-jdk openjdk-17-jre
   ```{{exec}}

1. Launch the app

   ```bash
   cd ~/course/rolldice/
   ./run.sh
   ```{{exec}}

   After some time, you should see that the Tomcat server has started. **In a new terminal**, you can test it with:

   ```bash
   curl localhost:8080/rolldice
   ```{{exec}}

Our app is a server returning a value between 1 and 6 when requested. Let's instrument it.

# Zero-code instrumentation

Luckily, our app is in Java and can be instrumented automatically with OpenTelemetry. Zero change of code. Promised.


1. Env variables:

   Execute the following commands:

   ```bash
   export NAMESPACE="opentelemetry-test-learning"
   export OTEL_RESOURCE_ATTRIBUTES="service.name=rolldice,deployment.environment=lab,service.namespace=${NAMESPACE},service.version=0.0.1,service.instance.id=${HOSTNAME}:8080"
   export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
   export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
   ```{{exec}}

   This will create environment variables that our OpenTelemetry runtime will read and reuse.

   What's happening here? We are configuring the OpenTelemetry Java agent to attach these OpenTelemetry _resource attributes_ to our signals:

   | Resource attribute name | Value                       | Description |
   | ----------------------- | --------------------------- | ----------- |
   | service.name            | rolldice                    | This holds the the canonical name of our application |
   | deployment.environment  | lab                         | The environment where the app is running. We've chosen "lab" here, but in the real world you might use something like "production", "test" or "development". |
   | service.instance.id     | (your IDE's hostname)       | The value of this attribute uniquely identifies your instance, which is useful if there are many instances of the app running. We use the **hostname** which, in this lab environment, is unique, and persists for the lifetime of your IDE session. |
   | service.namespace       | opentelemetry-test-learning | This allows us to distinguish your set of application(s) from the others in the same **environment**. So, when you have several applications running, you will be able to group them together more easily. |


   > OpenTelemetry components often use **environment variables** for configuration. The default value for  `OTEL_EXPORTER_OTLP_ENDPOINT` assumes that you want to send telemetry to an OpenTelemetry collector on `localhost`. We could omit this environment variable entirely, but we're including it explicitly here, to make it clear what's happening. 
   In production, you might set this value to `http://alloy.mycompany.com:4317`, or wherever your Alloy instance is located.

1. Inject the agent

   Now, we will edit `run.sh` to attach the [OpenTelemetry Java agent](https://opentelemetry.io/docs/zero-code/java/agent/): change the last line for this one: `java -javaagent:opentelemetry-javaagent.jar -jar ./target/rolldice-0.0.1-SNAPSHOT.jar`

   If you're not familiar with Java, the `-javaagent`: argument tells the Java process to attach an agent when the program starts. Agents are other Java programs which can interact and inspect the program that's running.

1. Start Rolldice with `./run.sh`. (Stop it first if it was still running.)

1. Generate some trafic
   
   In another terminal, run a bunch of `curl localhost:8080/rolldice?player=<my-name>` to ensure you get some traces saved.

# Check results

1.  Go to your [Grafana instance]({{TRAFFIC_HOST1_3000}}).

1.  From the main menu, go to **Explore**.
   - In Explore > Metrics, look for 
   - In Explore > Logs, you will see the log lines when a dice is rolled
   - In Explore > Traces, you will see the requests made on _Rolldice_

You can explore more into the trace, if you're feeling curious! In the next section of the workshop, we will manually create more signals.
