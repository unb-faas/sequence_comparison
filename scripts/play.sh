#/bin/bash
ACCESS_KEY=$1
SECRET_KEY=$2

if [ "${ACCESS_KEY}" == "" ]; then
  echo "ACCESS_KEY missing"
  echo "Example: ./play.sh ACCESS_KEY SECRET_KEY"
fi

if [ "${ACCESS_KEY}" == "" ]; then
  echo "SECRET_KEY missing"
  echo "Example: ./play.sh ACCESS_KEY SECRET_KEY"
fi

RESULTS_PATH=../sequences/test_cases_executions
TESTCASES_PATH=../sequences/test_cases_blocks
FAAS_URLS="https://64g3u3thci.execute-api.us-west-1.amazonaws.com/default/hirschberg_1024 \
https://2dwcokortj.execute-api.us-west-1.amazonaws.com/default/hirschberg_1536 \
https://9865beyfj3.execute-api.us-west-1.amazonaws.com/default/hirschberg_2048 \
https://9wylra8v4c.execute-api.us-west-1.amazonaws.com/default/hirschberg_2560 \
https://langmvdyu3.execute-api.us-west-1.amazonaws.com/default/hirschberg_3072"
ONDEMAND_INSTANCE_TYPES="t2.micro c6g.medium c6g.large"
TESTS_CONCURRENCE="1 5 10 15 20 25 30"
DATE=$(date +%Y%m%d%H%M%S)
BREAK_BETWEEN_TESTS_COEFICIENT=120 #SECONDS

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
  for URL in ${FAAS_URLS}; do
    TYPE=$(echo $URL | awk -F'_' '{print $2}' )
    #Creating testfiles
    for JSON in ${JSON_LIST}; do
      JSON_CONTENT=$(cat ${SOURCE_PATH}/$JSON)
      createBase64 "${JSON_CONTENT}" "faas-${TYPE}" "${TEST_CONCURRENCE}"
      echo ${base64} > ${RESULTS_FOLDER}/${JSON}.base64
    done

    for JSON in ${JSON_LIST}; do
      DATA=$(cat ${RESULTS_FOLDER}/${JSON}.base64)
      curl --silent --output /dev/null -X PUT -k -i "${URL}" --data "${DATA}" &
    done
  done
}

provisioning(){
  ACTION=$1
  terraform ${ACTION} -auto-approve -var "accesskey=${ACCESS_KEY}" -var "secretkey=${SECRET_KEY}" -var "instancetype=${TYPE}"
}

testOnOnDemand(){
  JSON_LIST=$1
  SOURCE_PATH=$2
  RESULTS_FOLDER=$3
  TEST_CONCURRENCE=$4
  for TYPE in ${ONDEMAND_INSTANCE_TYPES}; do
    echo "Provisioning ${TYPE} ..."
    cd provision
    PROVISION=$(provisioning apply)
    echo "Wait until ${TYPE} is configured"
    sleep 120
    IP=$(echo ${PROVISION} | sed 's/\x1b\[[0-9;]*m//g' | awk -F" = " '{print $2}' | sed -e 's/"\|,\|\[\|\]\|m\| //g')
    if [ "${IP}" != "" ]; then
      URL=http://${IP}:8000/${TYPE}
      #Creating testfiles
      for JSON in ${JSON_LIST}; do
        JSON_CONTENT=$(cat ../${SOURCE_PATH}/$JSON)
        createBase64 "${JSON_CONTENT}" "ondemand-${TYPE}" "${TEST_CONCURRENCE}"
        echo ${base64} > ../${RESULTS_FOLDER}/${JSON}.base64
      done

      for JSON in ${JSON_LIST}; do
        DATA=$(cat ../${RESULTS_FOLDER}/${JSON}.base64)
        curl --silent --output /dev/null -X PUT -k -i "${URL}" --data "{\"base64\":\"${DATA}\"}" &
      done
      echo "waiting until test run..."
      while [ "$(pgrep curl)" != "" ]; do
        echo -e "\r."
        sleep 10
      done
      echo "tests finished"
      echo "Unprovisioning ${TYPE} ..."
      PROVISION=$(provisioning destroy)
      cd ..
    else
      echo "Failure on provision ${TYPE}"
    fi 
  done

}


for TEST_CONCURRENCE in ${TESTS_CONCURRENCE}; do
  RESULTS_FOLDER=${RESULTS_PATH}/${DATE}/${TEST_CONCURRENCE}
  mkdir -p ${RESULTS_FOLDER}
  echo "Executing test ${TEST_CONCURRENCE}"
  JSON_LIST=$(ls ${TESTCASES_PATH}/${TEST_CONCURRENCE})
  testOnFaaS "${JSON_LIST}" "${TESTCASES_PATH}/${TEST_CONCURRENCE}" "${RESULTS_FOLDER}" "${TEST_CONCURRENCE}"
  echo "waiting until test run..."
  testOnOnDemand "${JSON_LIST}" "${TESTCASES_PATH}/${TEST_CONCURRENCE}" "${RESULTS_FOLDER}" "${TEST_CONCURRENCE}"
  let BREAK_BETWEEN_TESTS="${BREAK_BETWEEN_TESTS_COEFICIENT} * ${TEST_CONCURRENCE}"
  echo "waiting ${BREAK_BETWEEN_TESTS} seconds until test run..."
  sleep ${BREAK_BETWEEN_TESTS}
done
