Performance Test Results
----

#Machine
i9 8 cores, 32 GB

Environments:

| Environment | Version |
| ----------- | ------- |
| Hotspot     | Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11.0.7+8-LTS, mixed mode) |
| GraalVM CE  | 20.1.0 (Java Version 11.0.7) |
| GraalVM EE  | 20.1.1 (Java Version 11.0.8.0.2) |

#Runs
Avg and max response times are in milliseconds
Throughput is in requests per second

## No logging per request
| Framework | Environment | Throughput | avg  | max  |
| ----------|-------------| ----------:| ---: | ---: |
| Helidon   | Hotspot     | 90975.3    | 0.13 | 23   |  
| Helidon   | GraalVM EE  | 92652.6    | 0.12 | 25   |
| Helidon   | GraalVM CE  | 91633.8    | 0.18 | 80   |
| Helidon   | native CE   | 71007.6    | 0.49 | 136  |
| Helidon   | native EE   | 80173.1    | 0.35 | 106  |
| JAX-RS    | Hotspot     | 72801.4    | 0.46 | 84   |
| go        | go          | 92661.2    | 0.16 | 24   |

## Logging per request
| Framework | Environment | Throughput | avg  | max  |
| ----------|-------------| ----------:| ---: | ---: |
| Helidon   | Hotspot     | 30263.6    | 2.32 | 72   |
| Helidon   | GraalVM EE  | 29286.0    | 2.52 | 154  |
| Helidon   | GraalVM CE  | 31496.0    | 2.19 | 87   |
| Helidon   | native CE   | 26081.7    | 2.80 | 86   |
| Helidon   | native EE   | 29500.2    | 2.39 | 68   |
| JAX-RS    | Hotspot     | 23882.3    | 3.37 | 196  |
| go        | go          | 83201.6    | 0.30 | 25   |
