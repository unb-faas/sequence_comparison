TESTBASE_SEQUENCES_PATH=../sequences/covid19/selected
TARGET_PATH_JSON=../sequences/covid19/test_cases_json
mkdir -p ${TARGET_PATH_JSON}

extractSequenceContent()
{
    count=1
    sequence_title=''
    sequence_content=''
    for line in $(cat $1 | sed -e 's/ //g'); do
        if [ $count -eq 1 ]; then
          sequence_title=$line
        else
          if [ "${line}" != "" ];then
            sequence_content="${sequence_content}${line}"
          fi
        fi
        count=$((count + 1))
    done
}

createBase64(){
    title1=$1
    sequence1=$(echo $2 | tr '\n' ' ' | sed -e 's/ //g ')
    title2=$3
    sequence2=$(echo $4 | tr '\n' ' ' | sed -e 's/ //g ')
    id=$5
    json="{\"id\":\"${id}\",\"t1\":\"${title1}\",\"s1\":\"${sequence1}\",\"t2\":\"${title2}\",\"s2\":\"${sequence2}\"}"
    echo ${json} | tr '\r' ' ' | tr '\n' ' ' | tr '\t' ' '  | sed -e 's/ //g ' > /tmp/jsonToBase64.tmp
    base64=$(base64 /tmp/jsonToBase64.tmp)
    rm /tmp/jsonToBase64.tmp
}

execCounter=1
for sequence in $(find ${TESTBASE_SEQUENCES_PATH} | grep .fasta); do
    extractSequenceContent $sequence
    s1_content=${sequence_content}
    s1_title=${sequence_title}
    for sequence in $(find ${TESTBASE_SEQUENCES_PATH} | grep .fasta); do
      extractSequenceContent $sequence
      s2_content=${sequence_content}
      s2_title=${sequence_title}
      createBase64 ${s1_title} ${s1_content} ${s2_title} ${s2_content} ${execCounter}
      echo ${json} > ${TARGET_PATH_JSON}/${execCounter}.json
      execCounter=$((execCounter + 1))
    done
done