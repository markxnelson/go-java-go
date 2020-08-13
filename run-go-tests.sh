#!/bin/bash

#
# Parameters:
#    logging (logging|no-logging)
#    warmup  (warmup)
logging=$1
warmup=$2

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

current_dir=$PWD

time=$(date +"%Y-%m-%d_%H-%M")
directory=test-results/"go.${logging}.load.test."${time}

cd $current_dir/go

#config log
logging_properties_file=$current_dir/go/main.go
if [[ $logging = "no-logging" ]]
then
    echo "no-logging: Set level to ERROR"
    sed -i -e "s|AllowInfo|AllowError|g" $logging_properties_file
else
    echo "logging: Set level to INFO"
    sed -i -e "s|AllowError|AllowInfo|g" $logging_properties_file
fi

echo "main.go logging level============================"
cat $logging_properties_file | grep level.NewFilter
echo "================================================="

# kill previous webserver
pkill -f "go_service"

# make build
go build -o go_service ./...

#make run &
./go_service &

go_pid=$!

sleep 3

echo "Go app is running PID: ${go_pid}"

printMemory $go_pid

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
      	echo "Warmup in progress $((i*2))/1000"
      fi
    done
    printMemory $go_pid
    echo "Warmup is done."
else
    echo "No warmup"
fi

cd $current_dir

$JMETER/jmeter.sh -n -f -t test/test-plan.jmx -l "${directory}"/log.jtl -e -o "${directory}"

printMemory $go_pid

pkill -f "go_service"
