# Manual Instrumentation: Counting Dice Rolls

While automatic instrumentation provides great insights into your application, sometimes you want to track specific business metrics. Let's add manual instrumentation to count how many times each dice value is rolled.

## 1. Add OpenTelemetry Dependencies

First, ensure you're in the rolldice directory:
```bash
cd ~/course/rolldice/
```{{exec}}

Add these dependencies to your `pom.xml` inside the `<dependencies>` section:

```xml
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-api</artifactId>
    <version>1.34.1</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-boot-starter</artifactId>
    <version>2.1.0</version>
</dependency>
```

> Note: We're adding these dependencies while keeping the OpenTelemetry Java agent from the previous step. The agent provides automatic instrumentation, while these dependencies allow us to add custom metrics.

## 2. Modify RolldiceController

Update your `RolldiceController.java` to track dice rolls:

```java
package com.example.rolldice;

import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.api.metrics.Meter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;

@RestController
public class RolldiceController {
    private static final Logger logger = LoggerFactory.getLogger(RolldiceController.class);
    private final LongCounter diceRollCounter;

    public RolldiceController(Meter meter) {
        // Create a counter that tracks dice roll values
        this.diceRollCounter = meter
            .counterBuilder("dice.rolls")
            .setDescription("The number of times each value was rolled")
            .build();
    }

    @GetMapping("/rolldice")
    public String index(@RequestParam("player") Optional<String> player) {
        int result = this.getRandomNumber(1, 6);
        
        // Increment the counter with the rolled value
        diceRollCounter.add(1, 
            io.opentelemetry.api.common.Attributes.of(
                io.opentelemetry.api.common.AttributeKey.stringKey("value"), 
                String.valueOf(result)
            )
        );

        if (player.isPresent() && !player.get().isEmpty()) {
            logger.info("Player {} is rolling the dice, result: {}", player.get(), result);
        } else {
            logger.info("Anonymous player is rolling the dice, result: {}", result);
        }
        return Integer.toString(result) + "\n";
    }

    public int getRandomNumber(int min, int max) {
        return ThreadLocalRandom.current().nextInt(min, max + 1);
    }
}
```

## 3. Relaunch the app

1. Stop any instance of the app you have (`Ctrl` + `C` in the terminal running the app)

2. Rebuild and start the app:
```bash
./mvnw clean package
./run.sh
```{{exec}}

Wait until you see the Tomcat server startup message.

## 4. Generate some traffic

Let's reuse the command from previous step to generate traffic:

```bash
docker run --rm -i --network=host grafana/k6:latest run - < ~/course/load-test.js
```{{exec}}

The k6 load test will run for 5 minutes, simulating multiple players making dice rolls.

## 5. View the Results in Grafana

1. Open [Grafana]({{TRAFFIC_HOST1_3000}})
2. Go to Explore
3. Select the Mimir datasource
4. Enter this PromQL query to see the distribution of dice rolls:

```
sum by(value) (dice_rolls_total)
```

This will show you how many times each value (1-6) was rolled. Note that our metric name "dice.rolls" appears as "dice_rolls_total" in Prometheus/Grafana because:
- Dots are converted to underscores
- Counter metrics have "_total" appended

The metrics might take a minute to appear in Grafana as they are being collected and processed.

You can also calculate the rate of rolls over time:

```
rate(dice_rolls_total[5m])
```

## Understanding the Code

Let's break down the key parts of the manual instrumentation:

1. We create a `LongCounter` metric named "dice.rolls":
   ```java
   meter.counterBuilder("dice.rolls")
       .setDescription("The number of times each value was rolled")
       .build();
   ```

2. Each time the dice is rolled, we increment the counter with attributes:
   ```java
   diceRollCounter.add(1, 
       Attributes.of(AttributeKey.stringKey("value"), String.valueOf(result))
   );
   ```

3. The counter tracks:
   - Total number of rolls (using `dice_rolls_total`)
   - Distribution by value (using the "value" attribute)
   - Roll frequency over time (using `rate()`)

## Benefits of Manual Instrumentation

1. **Business Metrics**: Track metrics that matter to your application
   - In this case, we track dice roll distribution
   - Could be extended to track metrics per player

2. **Data Aggregation**: Group and analyze data by attributes
   - View total rolls for each value
   - Compare roll frequencies
   - Identify patterns in the distribution

3. **Real-time Insights**: Monitor application behavior as it happens
   - Watch dice roll patterns in real-time
   - Detect anomalies in the distribution
   - Track usage patterns during load tests

This example shows how manual instrumentation complements the automatic instrumentation from the Java agent. While the agent provides general metrics about our application, manual instrumentation lets us track business-specific metrics that matter to our use case.
