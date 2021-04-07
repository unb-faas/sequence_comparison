RESULT_PATH=$1
if [ ! ${RESULT_PATH} ];then
  echo "Missing path of results"
  exit 1
fi
CONCS_STRING=""
for rPATH in $(ls ${RESULT_PATH}); do
  CONCS=$(ls ${RESULT_PATH}/${rPATH})
  CONCS=$(echo ${CONCS} | tr ' ' '\n' | sort -n)
  for CONC in ${CONCS};do
    CONCS_STRING="${CONCS_STRING},total-duration-${CONC},avg-align-duration-${CONC},started_at-${CONC},finished_at-${CONC},avg-score-${CONC},avg-length-${CONC}"
  done
  break
done

echo "service${CONCS_STRING}"


for rPATH in $(ls ${RESULT_PATH}); do
  AVG=""
  STARTED_AT=""
  FINISHED_AT=""
  STARTED_AT_SECONDS=""
  FINISHED_AT_SECONDS=""
  DURATION=""
  STRING_OUT=""
  SCORE=""
  LEN=""
  
  for CONC in ${CONCS};do
    AVG="$(./sumDate.sh "`echo $(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.duration') | sed 's/"//g'`")"
    STARTED_AT="$(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.started_at' | sort -n | head -1)"
    FINISHED_AT="$(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.finished_at' | sort -n | tail -1)"
    SCORE="$(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.score' | jq -s add/length)"
    S1_LEN="$(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.s1.length' | jq -s add/length | bc)"
    S2_LEN="$(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.s1.length' | jq -s add/length | bc)"
    LEN=$(echo "$S1_LEN + $S2_LEN" | bc)
    LEN=$(echo "${LEN} / 2" | bc)
    STARTED_AT_SECONDS=$(echo ${STARTED_AT} | awk -F' ' '{print $2}' | awk -F'.' '{print $1}' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
    FINISHED_AT_SECONDS=$(echo ${FINISHED_AT} | awk -F' ' '{print $2}' | awk -F'.' '{print $1}' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
    DURATION=$(date -u -d "0 ${FINISHED_AT_SECONDS} seconds - ${STARTED_AT_SECONDS} seconds" +"%H:%M:%S")
    if [ "${STRING_OUT}" != "" ];then
      STRING_OUT="${STRING_OUT},${DURATION},${AVG},${STARTED_AT},${FINISHED_AT},${SCORE},${LEN}"
    else
                    STRING_OUT="${DURATION},${AVG},${STARTED_AT},${FINISHED_AT},${SCORE},${LEN}"
    fi
  done
  echo ${rPATH},${STRING_OUT}
done

