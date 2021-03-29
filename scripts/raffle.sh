TESTCASES_PATH=../sequences/test_cases_json
TESTCASES_TARGET=../sequences/test_cases_blocks
TESTS_LENGTH=$(seq 10)
MAX_CASE=$(ls -la ${TESTCASES_PATH} | wc -l)
MAX_CASE=$((MAX_CASE - 3))
for i in ${TESTS_LENGTH}; do
  FOLDER=${TESTCASES_TARGET}/${i}
  mkdir -p $FOLDER
  CONT=1
  while [ ${CONT} -le ${i} ]; do
    N=$(shuf -i 1-${MAX_CASE} -n 1)
    cp ${TESTCASES_PATH}/${N}.json ${FOLDER}
    CONT=$((CONT + 1))
  done
done