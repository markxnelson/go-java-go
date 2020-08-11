## Java vs Go load test

This repository contains the Java (JAX-RS and Helidon) and Go implementation of a tiny microservice.

The service provides the following endpoints:

* `/uppercase` converts the input string `s` to uppercase
* `/count` returns the length of the input string `s`
* `/metrics` returns Prometheus formatted metrics for the runtime and application metrics

### Load test

Set JMETER_HOME enviroment variable to the JMeter installation directory.
Set GRAALVM_HOME environment variable to the GraalVM installation.

Set the desired JAVA_HOME. Java implementation requires JDK11+.

Scripts are written and tested using MacOS.

#### Go

Use the `run-go-tests.sh` script which builds, runs the microservices application and JMeter.
Parameters:

1. **logging**|**no-logging** (*mandatory*): Switching log level between INFO (logging) and ERROR (no-logging). This option is introduced because logging can cause significant performance degradation.
2. **warmup** (*optional*): 1000 "warm up" calls before the load test.

For example:
```bash
run-go-tests.sh no-logging warmup
```
Console log contains information about RSS memory size. Before the warmup, before the load test and at the end of the load test.

#### Java (Helidon implementation)

Use the `run-helidon-tests.sh` script which builds, runs the microservices application and JMeter.
Parameters are the following:

1. **logging**|**no-logging** (*mandatory*): Switching log level between INFO (logging) and ERROR (no-logging). This option is introduced because logging can cause significant performance degradation.
2. **warmup**|**no-warmup** (*mandatory*): 1000 "warm up" calls before the load test.
3. **nmt**|**no-nmt** (*mandatory*): Native Memory Tracking to get details about Java/JVM memory usage. Note that enabling this will cause 5-10% performance overhead.
4. **Xms/Xmx** (*mandatory*): The initial and minimum Java heap size in MB. Both will get the same value.
5. **javaopts** (*optional*): Additional JVM options e.g. -XX:+UseG1GC

For example:
```bash
run-helidon-tests.sh no-logging warmup no-nmt 32
```
In case of Native Memory Tracking console log contains initial memory snapshot and increment at the end of the load test.

For the record the script saves the available and selected/used JDK version into a `java.version.txt` in the corresponding test-result folder.
#### Native Image (Helidon implementation compiled with Graal Native Image)

Use the `run-nativeimage-tests.sh` script which builds, runs the microservices application and JMeter.
Parameters are the following:

1. **logging**|**no-logging** (*mandatory*): Switching log level between INFO (logging) and ERROR (no-logging). This option is introduced because logging can cause significant performance degradation.
2. **warmup**|**no-warmup** (*mandatory*): 1000 "warm up" calls before the load test.
3. **nobuild** (*optional*): Skip Native Image build which can take a lot of time. In this case trying to use previously built executable binary.

For example:
```bash
run-nativeimage-tests.sh no-logging warmup
```
Console log contains information about RSS memory size. Before the warmup, before the load test and at the end of the load test.

### Test results

After the successful run the test results available in the `test-results` folder.
