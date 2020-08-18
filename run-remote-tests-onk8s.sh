#!/bin/bash

#
# Parameters:
#    implementation/application type (go|java|jlink|native)
#    ip_address or DNS of service or Load Balancer
#    port number
#    number of threads (1-1000) default 1000
app_type=$1
ip_address=$2
port_number=$3
jmeterthread=$4

[ -z $4 ] && jmeterthread=1000

echo $jmeterthread

current_dir=$PWD
header_host=""
deployment=""

if [[ $app_type = "go" ]]
then
  header_host="go-app.com"
  deployment="go-app-deployment"
elif [[ $app_type = "java" ]]
then
  header_host="java-helidon-app.com"
  deployment="java-helidon-app-deployment"
elif [[ $app_type = "jlink" ]]
then
  header_host="java-helidon-jlink-app.com"
  deployment="java-helidon-jlink-app-deployment"
elif [[ $app_type = "native" ]]
then
  header_host="native-app.com"
  deployment="native-app-deployment"
else
  echo "Application type is not defined (go|java|jlink|native)"
  exit 1
fi


if [ -z ${ip_address+x} ]
then
  echo "OKE Loadbalancer IP is not defined!"
  exit 1
else
  echo "OKE Loadbalancer IP is set to ${ip_address}"
fi

if [ -z ${JMETER_HOME+x} ]
then
  echo "JMETER_HOME is unset!"
  exit 1
else
  echo "JMETER_HOME is set to ${JMETER_HOME}"
fi

time=$(date +"%Y-%m-%d_%H-%M")
directory=test-results/"remote.${app_type}.load.test."${time}

cd $current_dir

JVM_ARGS="-Xms512m -Xmx2048m"

$JMETER_HOME/bin/jmeter.sh -n -f  \
  -Joke_lb_ipaddress=$ip_address \
  -Jheader_host=$header_host \
  -Jjmeter_load_threads=$jmeterthread \
  -Joke_lb_port=$port_number \
  -t test/test-plan-remote.jmx \
  -l "${directory}"/log.jtl \
  -e -o "${directory}"

mv $current_dir/test_results.csv $directory/
mv $current_dir/oke_usage* $directory/

cat $directory/statistics.json | grep meanResTime
cat $directory/statistics.json | grep throughput

exit 0
