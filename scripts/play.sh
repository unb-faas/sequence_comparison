#/bin/bash
ACCESS_KEY=$1
SECRET_KEY=$2
TESTS=$3
DEBUG=$4
OUTPUT_CONFIG="--silent --output /dev/null"
if [ "${DEBUG}" != "" ]; then
  OUTPUT_CONFIG=""
fi

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

showExample(){
  echo "Example: ./play.sh ACCESS_KEY SECRET_KEY 'ondemand faas'"
}

if [ "${ACCESS_KEY}" == "" ]; then
  echo "ACCESS_KEY missing"
  showExample
  exit 1
fi

if [ "${SECRET_KEY}" == "" ]; then
  echo "SECRET_KEY missing"
  showExample
  exit 1
fi

if [ "${TESTS}" == "" ]; then
  echo "TESTS list missing"
  showExample
  exit 1
fi

RESULTS_PATH=../sequences/test_cases_executions
TESTCASES_PATH=../sequences/test_cases_blocks
FAAS_URLS="https://64g3u3thci.execute-api.us-west-1.amazonaws.com/default/hirschberg_1024 \
https://2dwcokortj.execute-api.us-west-1.amazonaws.com/default/hirschberg_1536 \
https://9865beyfj3.execute-api.us-west-1.amazonaws.com/default/hirschberg_2048 \
https://9wylra8v4c.execute-api.us-west-1.amazonaws.com/default/hirschberg_2560 \
https://langmvdyu3.execute-api.us-west-1.amazonaws.com/default/hirschberg_3072"

                         #4vCPU     8vCPU       16vcpu      32vcpu
ONDEMAND_INSTANCE_TYPES="t3a.xlarge t4g.2xlarge c5a.4xlarge c5a.8xlarge"

LOCAL_INSTANCE="localhost"
TESTS_CONCURRENCE="1 20 40 60 80 100"
DATE=$(date +%Y%m%d%H%M%S)

createBase64(){
    json=$1
    type=$2
    concurrence=$3
    echo "${json:$i:-1},\"type\":\"${type}\",\"concurrence\":\"${concurrence}\"}" | tr '\r' ' ' | tr '\n' ' ' | tr '\t' ' '  | sed -e 's/ //g ' > /tmp/jsonToBase64.tmp
    base64=$(base64 /tmp/jsonToBase64.tmp)
    rm /tmp/jsonToBase64.tmp
}

testOnFaaS(){
  JSON_LIST=$1
  SOURCE_PATH=$2
  RESULTS_FOLDER=$3
  TEST_CONCURRENCE=$4
  INSTANCE=$5
  TYPE=$(echo ${INSTANCE} | awk -F'_' '{print $2}' )
  for JSON in ${JSON_LIST}; do
    DATA=$(cat ${RESULTS_FOLDER}/${JSON}.base64)
    curl ${OUTPUT_CONFIG} -X PUT -k -i "${INSTANCE}" --data "${DATA}" &
  done
  let BREAK_BETWEEN_TESTS="${TYPE} / 2"
  echo "waiting ${BREAK_BETWEEN_TESTS} seconds until test runs..."
  sleep ${BREAK_BETWEEN_TESTS}  
}

provisioning(){
  ACTION=$1
  echo "Provisioning to ${ACTION}: ${INSTANCE} ..."
  cd provision
  terraform init
  terraform refresh -var "accesskey=${ACCESS_KEY}" -var "secretkey=${SECRET_KEY}" -var "instancetype=${INSTANCE}"
  if [ "${ACTION}" == "apply" ]; then
    PROVISION=$(terraform apply -auto-approve -var "accesskey=${ACCESS_KEY}" -var "secretkey=${SECRET_KEY}" -var "instancetype=${INSTANCE}")
  fi
  if [ "${ACTION}" == "destroy" ]; then
    terraform destroy -auto-approve -var "accesskey=${ACCESS_KEY}" -var "secretkey=${SECRET_KEY}" -var "instancetype=${INSTANCE}"
    rm -rf terraform.tfstate*
  else
    echo ${PROVISION}
    echo ${PROVISION} >> /tmp/provision-${INSTANCE}
    IP=$(echo ${PROVISION} | sed 's/\x1b\[[0-9;]*m//g' | awk -F"instance_ips = " '{print $2}' | sed -e 's/"\|,\|\[\|\]\|m\| //g')
    echo "Instance IP: ${IP}"
    if [ "${IP}" == "" ]; then
      echo "IP is null"
      exit 3
    fi 
    if ! valid_ip ${IP}; then
      echo "Failure on provision ${INSTANCE}: invalid IP"
      exit 3
    fi
    echo "Wait until ${INSTANCE} is configured"
    TIMEOUT_COUNT=180
    SERVICE_UP=false
    while [ ${TIMEOUT_COUNT} -gt 0 ] && [ "${SERVICE_UP}" == "false" ]; do
      TEST=$(curl http://${IP}:8000 | grep "\"detail\":")
      if [ "${TEST}" != "" ]; then
        SERVICE_UP=true
      else
        TIMEOUT_COUNT=$((TIMEOUT_COUNT - 1))
      fi
      sleep 1
    done 
  fi
  cd -  
}

testOnOnDemand(){
  JSON_LIST=$1
  SOURCE_PATH=$2
  RESULTS_FOLDER=$3
  TEST_CONCURRENCE=$4
  INSTANCE=$5
  provisioning 'apply'
  URL=http://${IP}:8000/${INSTANCE}
  for JSON in ${JSON_LIST}; do
    DATA=$(cat ${RESULTS_FOLDER}/${JSON}.base64)
    curl ${OUTPUT_CONFIG} -X PUT -k -i "${URL}" --data "{\"base64\":\"${DATA}\"}" &
  done
  echo "waiting until test runs..."
  while [ "$(ps -aux | grep curl | grep ${IP})" != "" ]; do
    echo -e "\r."
    sleep 10
  done
  sleep 30
  provisioning 'destroy'
}

testOnLocalhost(){
  JSON_LIST=$1
  SOURCE_PATH=$2
  RESULTS_FOLDER=$3
  TEST_CONCURRENCE=$4
  INSTANCE=$5
  URL=http://localhost:8000/${INSTANCE}
  for JSON in ${JSON_LIST}; do
    DATA=$(cat ${RESULTS_FOLDER}/${JSON}.base64)
    curl ${OUTPUT_CONFIG} -X PUT -k -i "${URL}" --data "{\"base64\":\"${DATA}\"}" &
  done
  echo "waiting until test runs..."
  while [ "$(pgrep curl)" != "" ]; do
    echo -e "\r."
    sleep 10
  done
  sleep 30
}

set -x
for TEST in ${TESTS}; do
   case $TEST in
    'faas') 
      TESTFUNC=testOnFaaS
      TESTINSTANCES=${FAAS_URLS}
    ;;
    'ondemand') 
      TESTFUNC=testOnOnDemand
      TESTINSTANCES=${ONDEMAND_INSTANCE_TYPES}
    ;;
    'local') 
      TESTFUNC=testOnLocalhost
      TESTINSTANCES=${LOCAL_INSTANCE}
    ;;
    *) echo "Invalid test!" 
      exit 2;;
  esac
  for INSTANCE in ${TESTINSTANCES}; do
    case $TEST in
      'faas') 
        TESTTYPE="faas-$(echo ${INSTANCE} | awk -F_ '{print $2}')"
      ;;
      'ondemand') 
        TESTTYPE="ondemand-${INSTANCE}"
      ;;
      'local') 
        TESTTYPE="${INSTANCE}"
      ;;
      *) echo "Invalid test!" 
        exit 2;;
    esac
    echo "Running test: ${TESTFUNC} on ${INSTANCE}"
    for TEST_CONCURRENCE in ${TESTS_CONCURRENCE}; do
      RESULTS_FOLDER=${RESULTS_PATH}/${DATE}/${TEST_CONCURRENCE}
      mkdir -p ${RESULTS_FOLDER}
      echo "Executing test with ${TEST_CONCURRENCE} of concurrence"
      SOURCE_PATH=${TESTCASES_PATH}/${TEST_CONCURRENCE}
      JSON_LIST=$(ls ${SOURCE_PATH})
      for JSON in ${JSON_LIST}; do
        JSON_CONTENT=$(cat ${SOURCE_PATH}/$JSON)
        createBase64 "${JSON_CONTENT}" "${TESTTYPE}" "${TEST_CONCURRENCE}"
        echo ${base64} > ${RESULTS_FOLDER}/${JSON}.base64
      done
      ${TESTFUNC} "${JSON_LIST}" "${TESTCASES_PATH}/${TEST_CONCURRENCE}" "${RESULTS_FOLDER}" "${TEST_CONCURRENCE}" "${INSTANCE}"
    done
  done
done
