#!/bin/bash

#
# Parameters:
#    logging (logging|no-logging)
#    warmup  (warmup)
#    build   (nobuild)
logging=$1
warmup=$2
nobuild=$3

function printMemory {
  mem=$(ps -o rss= -p "$1")
  printf "Memory usage: $mem kB\n"
}

if [ -z ${JMETER_HOME+x} ]
then
  echo "JMETER_HOME is unset!"
  exit 1
else
  echo "JMETER_HOME is set to ${JMETER_HOME}"
fi
JMETER=$JMETER_HOME/bin

if [ -z ${JMETER_HOME+x} ];
then
  echo "GRAALVM_HOME is unset!"
  exit 1
else
  echo "GRAALVM_HOME is set to ${GRAALVM_HOME}"
fi

current_dir=$PWD

time=$(date +"%Y-%m-%d_%H-%M")
directory=test-results/"native-image.${logging}.load.test."${time}

cd $current_dir/java-helidon

#config log
logging_properties_file=$current_dir/java-helidon/src/main/resources/logging.properties
if [[ $logging = "no-logging" ]]
then
    echo "no-logging: Set level to WARNING"
    sed -i -e "s|INFO|WARNING|g" $logging_properties_file
else
    echo "logging: Set level to INFO"
    sed -i -e "s|WARNING|INFO|g" $logging_properties_file
fi

echo "logging.properties============================"
cat $logging_properties_file | grep .level
echo "=============================================="

# kill previous webserver
pkill -f helidon-quickstart-se

# build GraalVM Native Image
if [[ $nobuild = "nobuild" ]]
then
  echo "nobuild: Skip Native Image build. Using available binary."
else
  mvn package -Pnative-image -Dmaven.test.skip=true
fi

nativeimage=$current_dir/java-helidon/target/helidon-quickstart-se
if [[ -f "$nativeimage" ]]
then
  $nativeimage &
else
  echo "Native Image binary is not available to use. Check nobuild option and run again."
  exit 1
fi

nativeimage_pid=$!

sleep 2

echo "Native Image app is running PID: ${nativeimage_pid}"

printMemory $nativeimage_pid

#warm up
if [[ $warmup = "warmup" ]]
then
    echo "Warmup...."
    curl -X POST -H "Content-Type: application/json" -d '{"s":"hello"}' http://localhost:8080/uppercase
    echo ""
    curl -X POST -H "Content-Type: application/json" -d '{"s":"hello"}' http://localhost:8080/count
    echo ""
    echo "Switching off the output for mass warmup."
    for i in {1..500}
    do
      curl -s -X POST -H "Content-Type: application/json" -d '{"s":"hello"}' http://localhost:8080/uppercase > /dev/null
      curl -s -X POST -H "Content-Type: application/json" -d '{"s":"hello"}' http://localhost:8080/count > /dev/null
      if ! ((i % 50)); then
      	echo "Warmup in progress ${i}/1000"
      fi
    done
    printMemory $nativeimage_pid
    echo "Warmup is done."
else
    echo "No warmup."
fi

cd $current_dir

$JMETER/jmeter.sh -n -f -t test/test-plan.jmx -l "${directory}"/log.jtl -e -o "${directory}"

printMemory $nativeimage_pid

pkill -f helidon-quickstart-se
