#!/bin/bash

#
# Parameters:
#    type (go|jax-rs|hotspot|native-ce|native-ee|graal-ce|graal-ee)
#    logging (logging|no-logging)

JMETER_HOME=~/bin/apache-jmeter-5.3
JMETER=$JMETER_HOME/bin

build=$1
logging=$2
time=$(date +"%Y-%m-%d_%H-%M")
directory=test/"${build}-${logging}.load.test."${time}

$JMETER/jmeter.sh -n -t test/test-plan.jmx -l "${directory}"/log.jtl -e -o "${directory}"