## Tiny microservice implemented in Java

This directory contains the Java implementation of the tiny microservice.

The service provides the following endpoints:

* `/uppercase` converts the input string `s` to uppercase
* `/count` returns the length of the input string `s`
* `/metrics` returns Prometheus formatted metrics for the runtime and application metrics


### Build and run the application for functional test

With JDK11+
```bash
mvn package
java -jar target/helidon-quickstart-se.jar
```

### Using the service

To use the service:

```
curl -X POST -d '{"s":"hello"}' http://localhost:8080/uppercase
curl -X POST -d '{"s":"hello"}' http://localhost:8080/count
curl http://localhost:8080/metrics
```

### Build a native image with GraalVM for performance test

GraalVM allows you to compile your programs ahead-of-time into a native
 executable. See https://www.graalvm.org/docs/reference-manual/aot-compilation/
 for more information.

#### Local build

Download Graal VM at https://www.graalvm.org/downloads, the versions
 currently supported for Helidon are `20.1.0` and above.

```
# Setup the environment
export GRAALVM_HOME=/path
# build the native executable
mvn package -Pnative-image
```

You can also put the Graal VM `bin` directory in your PATH, or pass
 `-DgraalVMHome=/path` to the Maven command.

See https://github.com/oracle/helidon-build-tools/tree/master/helidon-maven-plugin#goal-native-image
 for more information.

Start the application:

```
./target/helidon-quickstart-se
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
export JMETER=/Users/pnagy/u01/apache-jmeter-5.3/bin
```
```bash
$JMETER/jmeter.sh -n -t test/Test\ Plan\ for\ Go\ Implementation.jmx -l test/"java.load.test."$(date +"%Y-%m-%d_%H-%M")/log.jtl -e -o test/"java.load.test."$(date +"%Y-%m-%d_%H-%M")
```
