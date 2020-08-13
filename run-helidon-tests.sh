#!/bin/bash

#
# Parameters:
#    logging  (logging|no-logging)
#    warmup   (warmup|no-warmup)
#    nmt      (nmt|no-nmt)         Native Memory Tracking
#    Xmx/Xms  (int MB)             Initial and max size of the heap
#    javaopts (JAVA OPTIONS)       Extra Java Options e.g.: -XX:+UseG1GC

if [ -z ${JMETER_HOME+x} ]
then
  echo "JMETER_HOME is unset!"
  exit 1
else
  echo "JMETER_HOME is set to ${JMETER_HOME}"
fi
JMETER=$JMETER_HOME/bin

current_dir=$PWD

logging=$1
warmup=$2
nmt=$3
xmxs=$4
javaopts=$5
time=$(date +"%Y-%m-%d_%H-%M")
directory=test-results/"java-helidon.${logging}.load.test."${time}

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
pkill -f helidon-quickstart-se.jar

mvn package -Dmaven.test.skip=true

# Native Memory Tracking - nmt
# https://docs.oracle.com/javase/8/docs/technotes/guides/vm/nmt-8.html
if [[ $nmt = "nmt" ]]
then
  java -XX:NativeMemoryTracking=summary -XX:+UnlockDiagnosticVMOptions -XX:+PrintNMTStatistics -Xms${xmxs}m -Xmx${xmxs}m ${javaopts} -jar target/helidon-quickstart-se.jar &
else
  java -Xms${xmxs}m -Xmx${xmxs}m ${javaopts} -jar target/helidon-quickstart-se.jar &
fi

helidon_pid=$!

sleep 3

echo "Helidon app is running: ${helidon_pid}"

# https://docs.oracle.com/javase/8/docs/technotes/guides/vm/nmt-8.html
jcmd $helidon_pid VM.native_memory baseline scale=KB

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
    echo "Warmup is done."
else
    echo "No warmup"
fi

cd $current_dir

$JMETER/jmeter.sh -n -f -t test/test-plan.jmx -l "${directory}"/log.jtl -e -o "${directory}"

mv test_results $directory/test_results.csv

# https://www.baeldung.com/native-memory-tracking-in-jvm
jcmd $helidon_pid VM.native_memory summary.diff scale=KB

#store Java version in file
java_version_file=$current_dir/$directory/java.version.txt
echo "/usr/libexec/java_home -V===>" >> $java_version_file
/usr/libexec/java_home -V >> $java_version_file 2>&1
echo "java -version===>" >> $java_version_file
java -version >> $java_version_file 2>&1

kill -9 $helidon_pid
