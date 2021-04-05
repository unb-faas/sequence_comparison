#!/bin/sh
#./sumDate.sh "`echo $(cat ~/Desktop/ondemand-t3.small/5/* | jq '.duration') | sed 's/"//g'`"
EPOCH='jan 1 1970'
sum=0
count=0
for i in $1; do
  sum="$(date -u -d "$EPOCH $i" +%s) + $sum"
  count=$((count+1))
done
sum=${sum}|bc
sum=$(expr ${sum})
if [ ${count} -gt 0 ];then
avg=$(expr ${sum} / ${count})
echo $(expr ${avg} / 60 / 60):$(expr ${avg} / 60):$(expr ${avg} % 60)
fi
