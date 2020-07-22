## Tiny microservice implemented in Go

This directory contains the GO implementation of the tiny microservice. 

The service provides the following endpoints: 

* `/uppercase` converts the input string `s` to uppercase
* `/count` returns the length of the input string `s`
* `/metrics` returns Prometheus formated metrics for the runtime and application metrics

The service has middleware for logging and instrumentation.

### Build the service

To build the service:

```
make build
```

### Run the service

To run the service:

```
make run
```

### Using the service

To use the service:

```
curl -X POST -d '{"s":"hello"}' http://localhost:8080/uppercase
curl -X POST -d '{"s":"hello"}' http://localhost:8080/count
curl http://localhost:8080/metrics
```

