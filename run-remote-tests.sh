#!/bin/bash

#
# Parameters:
#    implementation/application type (go|java|jlink|native)
#    ip_address of LB (xxx.xxx.xxx.xxx)
#    warmup (warmup|nowarmup)
app_type=$1
ip_address=$2
warmup=$3

current_dir=$PWD
header_host=""

#shopt -s expand_aliases
#alias oke_resource_usage_util='kubectl get nodes | grep node | awk '\''{print $1}'\'' | xargs -I {} sh -c '\''echo {} ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo '\'''

rm -f oke_usage*
function oke_usage() {

  if [ -z ${KUBECONFIG+x} ]
  then
    echo "KUBECONFIG is not defined!"
    return 1
  fi

  nodes=$(kubectl get node --no-headers -o custom-columns=NAME:.metadata.name)

  for node in $nodes; do
    echo "Node: $node" | tee -a oke_usage.$node.txt
    kubectl describe node $node | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- | tee -a oke_usage.$node.txt
  done
}

oke_usage

if [[ $app_type = "go" ]]
then
  header_host="go-app.com"
elif [[ $app_type = "java" ]]
then
  header_host="java-helidon-app.com"
elif [[ $app_type = "jlink" ]]
then
  header_host="java-helidon-jlink-app.com"
elif [[ $app_type = "native" ]]
then
  header_host="native-app.com"
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

JVM_ARGS="-Xms512m -Xmx2048m"

$JMETER_HOME/bin/jmeter.sh -n -f  \
  -Joke_lb_ipaddress=$ip_address \
  -Jheader_host=$header_host \
  -t test/test-plan-remote.jmx \
  -l "${directory}"/log.jtl \
  -e -o "${directory}" &

jmeter_proc_id=$!

while kill -0 "$jmeter_proc_id" >/dev/null 2>&1; do
  oke_usage
  sleep 1
done

mv $current_dir/test_results.csv $directory/
mv $current_dir/oke_usage* $directory/


exit 0
