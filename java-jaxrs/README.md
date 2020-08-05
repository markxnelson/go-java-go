## Tiny microservice implemented in JAX-RS

This directory contains the pure JAX-RS implementation of the tiny microservice.

The service provides the following endpoints:

* `/uppercase` converts the input string `s` to uppercase
* `/count` returns the length of the input string `s`
* `/metrics` returns Prometheus formatted metrics for the runtime and application metrics


### Build and run the application for functional test

With JDK11+
```bash
mvn clean install
mvn -Djava.util.logging.config.file="./src/main/resources/logging.properties" exec:java
```

### Using the service

To use the service:

```
curl -X POST -d '{"s":"hello"}' http://localhost:8080/uppercase
curl -X POST -d '{"s":"hello"}' http://localhost:8080/count
curl http://localhost:8080/metrics
```

### Try metrics

```
# Prometheus Format
curl -s -X GET http://localhost:8080/metrics
# TYPE base:gc_g1_young_generation_count gauge
. . .

# JSON Format
curl -H 'Accept: application/json' -X GET http://localhost:8080/metrics
{"base":...
. . .

```

### Load test

```bash
export JMETER=<PATH_TO_JMETER>/apache-jmeter-5.3/bin
```
```bash
$JMETER/jmeter.sh -n -t test/Test\ Plan\ for\ Go\ Implementation.jmx -l test/"java-jaxrs.load.test."$(date +"%Y-%m-%d_%H-%M")/log.jtl -e -o test/"java-jaxrs.load.test."$(date +"%Y-%m-%d_%H-%M")
```
