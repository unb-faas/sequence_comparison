RESULT_PATH=~/Desktop/test_results
for rPATH in $(ls ${RESULT_PATH}); do
  AVG=""
  CONCS=$(ls ${RESULT_PATH}/${rPATH})
  CONCS=$(echo ${CONCS} | tr ' ' '\n' | sort -n)
  for CONC in ${CONCS};do
    if [ $(ls ${RESULT_PATH}/${rPATH}/${CONC}/ | wc -l) -gt 0 ]; then
      if [ "${AVG}" != "" ];then
    	AVG="${AVG},$(./sumDate.sh "`echo $(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.duration') | sed 's/"//g'`")"
      else
    	AVG="$(./sumDate.sh "`echo $(cat ${RESULT_PATH}/${rPATH}/${CONC}/* | jq '.duration') | sed 's/"//g'`")"
      fi
    else
	AVG="${AVG},"
    fi
  done
  echo ${rPATH},${AVG}
done

