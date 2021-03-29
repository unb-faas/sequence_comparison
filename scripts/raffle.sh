#/bin/bash
if [ "${1}" == "" ]; then
  echo "Block size missing"
  exit 1
fi

BLOCKS=$1
TESTCASES_PATH=../sequences/test_cases_json
TESTCASES_TARGET=../sequences/test_cases_blocks
TESTS_LENGTH=$(seq ${BLOCKS})
MAX_CASE=$(ls -la ${TESTCASES_PATH} | wc -l)
MAX_CASE=$((MAX_CASE - 3))


getNumber(){
  N=false
  while [ "${N}" == "false" ];do
    N=$(shuf -i 1-${MAX_CASE} -n 1)
    for i in ${NUMBERLIST};do
      if [ "$i" == "$N" ]; then
        N=false
      fi
    done
  done
  NUMBERLIST="${NUMBERLIST} ${N}"
}

for i in ${TESTS_LENGTH}; do
  NUMBERLIST=""
  FOLDER=${TESTCASES_TARGET}/${i}
  mkdir -p $FOLDER
  CONT=1
  while [ ${CONT} -le ${i} ]; do
    getNumber
    ln -s ../../${TESTCASES_PATH}/${N}.json ${FOLDER}/${N}.json
    CONT=$((CONT + 1))
  done
done

