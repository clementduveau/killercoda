# Manual Instrumentation with OpenTelemetry

While automatic instrumentation is powerful, manual instrumentation allows for more precise and business-specific observability. Let's enhance our Rolldice application with custom instrumentation.

## 1. Add OpenTelemetry Dependencies

First, add these dependencies to your `pom.xml`:

```xml
<dependencies>
    <!-- OpenTelemetry API -->
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-api</artifactId>
        <version>1.34.1</version>
    </dependency>
    
    <!-- OpenTelemetry SDK -->
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-sdk</artifactId>
        <version>1.34.1</version>
    </dependency>
</dependencies>
```

## 2. Create a Telemetry Configuration

Create a new class `TelemetryConfig.java`:

```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.metrics.Meter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class TelemetryConfig {
    
    @Bean
    public Tracer tracer(OpenTelemetry openTelemetry) {
        return openTelemetry.getTracer("com.example.rolldice");
    }
    
    @Bean
    public Meter meter(OpenTelemetry openTelemetry) {
        return openTelemetry.getMeter("com.example.rolldice");
    }
}
```

## 3. Custom Span Creation

Modify your RollDiceController to add custom spans:

```java
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RollDiceController {
    private final Tracer tracer;
    private final Random random;
    
    public RollDiceController(Tracer tracer) {
        this.tracer = tracer;
        this.random = new Random();
    }
    
    @GetMapping("/rolldice")
    public int rollDice() {
        // Create a custom span
        Span span = tracer.spanBuilder("roll_dice_operation")
            .setAttribute("component", "dice_roller")
            .startSpan();
            
        try (Scope scope = span.makeCurrent()) {
            // Add business logic timing
            Span businessSpan = tracer.spanBuilder("generate_random_number")
                .startSpan();
            
            try {
                int result = random.nextInt(6) + 1;
                businessSpan.setAttribute("dice.value", result);
                return result;
            } catch (Exception e) {
                businessSpan.setStatus(StatusCode.ERROR);
                businessSpan.recordException(e);
                throw e;
            } finally {
                businessSpan.end();
            }
        } finally {
            span.end();
        }
    }
}
```

## 4. Add Custom Metrics

Create custom metrics to track business-specific data:

```java
import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.api.metrics.Meter;

@RestController
public class RollDiceController {
    private final LongCounter rollCounter;
    private final LongCounter valueCounter;
    
    public RollDiceController(Tracer tracer, Meter meter) {
        // ... previous constructor code ...
        
        // Create counters
        this.rollCounter = meter
            .counterBuilder("dice.rolls.total")
            .setDescription("Total number of dice rolls")
            .build();
            
        this.valueCounter = meter
            .counterBuilder("dice.value.count")
            .setDescription("Count of specific dice values")
            .build();
    }
    
    @GetMapping("/rolldice")
    public int rollDice() {
        // ... previous span creation code ...
        
        try (Scope scope = span.makeCurrent()) {
            int result = random.nextInt(6) + 1;
            
            // Increment metrics
            rollCounter.add(1);
            valueCounter.add(1, Attributes.of(
                AttributeKey.stringKey("value"), String.valueOf(result)
            ));
            
            return result;
        }
    }
}
```

## 5. Add Baggage for Cross-cutting Concerns

Implement baggage to carry data across service boundaries:

```java
import io.opentelemetry.api.baggage.Baggage;
import io.opentelemetry.api.baggage.BaggageEntry;

@RestController
public class RollDiceController {
    @GetMapping("/rolldice")
    public int rollDice() {
        // Create baggage with user context
        Baggage.current()
            .toBuilder()
            .put("game.id", UUID.randomUUID().toString())
            .put("game.type", "dice")
            .build()
            .makeCurrent();
            
        // ... rest of the method
    }
}
```

## 6. View Enhanced Telemetry

1. Rebuild and restart your application:
```bash
./mvnw clean package
./run.sh
```{{exec}}

2. Generate some traffic:
```bash
curl localhost:8080/rolldice
```{{exec}}

3. Open [Grafana]({{TRAFFIC_HOST1_3000}}) and explore:
   - New custom spans under Traces
   - Custom metrics under Metrics
   - Cross-cutting context in traces via baggage

## Custom Dashboards

Create a new dashboard in Grafana to visualize:
1. Roll distribution (using `dice.value.count`)
2. Roll frequency (using `dice.rolls.total`)
3. Operation latency (using span duration)

Example PromQL queries:
```
# Roll distribution
sum(rate(dice_value_count_total[5m])) by (value)

# Roll frequency
rate(dice_rolls_total[5m])

# Operation latency
histogram_quantile(0.95, sum(rate(roll_dice_operation_duration_milliseconds_bucket[5m])) by (le))
```

## Benefits of Manual Instrumentation

1. **Business Context**: Add domain-specific attributes and metrics
2. **Fine-grained Control**: Create custom spans for specific operations
3. **Rich Metrics**: Track business-specific KPIs
4. **Cross-cutting Concerns**: Use baggage for request-scoped metadata
5. **Custom Error Handling**: Detailed error tracking and status management

## Next Steps

- Implement custom samplers for specific business cases
- Add more business metrics
- Create custom span processors
- Implement cross-service correlation
