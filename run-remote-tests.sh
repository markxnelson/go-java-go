#!/bin/bash

#
# Parameters:
#    implementation/application type (go|java|jlink|native)
#    ip_address or DNS of service or Load Balancer
#    number of threads (1-1000) default 1000
app_type=$1
ip_address=$2
jmeterthread=$3

[ -z $3 ] && jmeterthread=1000

echo $jmeterthread

current_dir=$PWD
header_host=""
deployment=""

rm -f oke_usage*
function oke_usage() {

  if [ -z ${KUBECONFIG+x} ]
  then
    return 1
  fi

  nodes=$(kubectl get node --no-headers -o custom-columns=NAME:.metadata.name)

  for node in $nodes; do
    echo "Node: $node" >> oke_usage.$node.txt
    kubectl describe node $node | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- >> oke_usage.$node.txt
  done
}

oke_usage

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

if [ -z ${KUBECONFIG+x} ]
then
  echo "KUBECONFIG is not defined!"
fi

time=$(date +"%Y-%m-%d_%H-%M")
directory=test-results/"remote.${app_type}.load.test."${time}

#warm up
if [[ $warmup = "warmup" ]]
then
    echo "Warmup...."
    curl -X POST -H "Content-Type: application/json" -H "host: $header_host" -d '{"s":"hello"}' http://$ip_address/uppercase
    echo ""
    curl -X POST -H "Content-Type: application/json" -H "host: $header_host" -d '{"s":"hello"}' http://$ip_address/count
    echo ""
    echo "Switching off the output for mass warmup."
    for i in {1..500}
    do
      curl -s -X POST -H "Content-Type: application/json" -H "host: $header_host" -d '{"s":"hello"}' http://$ip_address/uppercase > /dev/null
      curl -s -X POST -H "Content-Type: application/json" -H "host: $header_host" -d '{"s":"hello"}' http://$ip_address/count > /dev/null
      if ! ((i % 50)); then
      	echo "Warmup in progress $((i*2))/1000"
      fi
    done
    echo "Warmup is done."
else
    echo "No warmup."
fi

cd $current_dir

echo $directory

JVM_ARGS="-Xms512m -Xmx2048m"

$JMETER_HOME/bin/jmeter.sh -n -f  \
  -Joke_lb_ipaddress=$ip_address \
  -Jheader_host=$header_host \
  -Jjmeter_load_threads=$jmeterthread \
  -t test/test-plan-remote.jmx \
  -l "${directory}"/log.jtl \
  -e -o "${directory}" &

jmeter_proc_id=$!

podnum=2
while kill -0 "$jmeter_proc_id" >/dev/null 2>&1; do
  # oke_usage
  # if (( $podnum < 101 ));
  # then
  #   kubectl scale --replicas=$podnum deployment $deployment -n gojavago
  #   ((podnum=podnum+1))
  # fi
  # pods=$(kubectl get po -n gojavago | grep -o ''"$deployment"'' | wc -l)
  # printf "Running pods: $pods"
  # sleep 1
done

mv $current_dir/test_results.csv $directory/
mv $current_dir/oke_usage* $directory/

cat $directory/statistics.json | grep meanResTime
cat $directory/statistics.json | grep throughput

exit 0
