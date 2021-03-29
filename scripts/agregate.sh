cont=1
last=""
for i in $(cat list.sorted);do
  if [ "$last" != "$i" ] && [ "$last" != "" ]; then
    echo $i  $cont
    cont=1
    last=$i
  else
    last=$i
    cont=$((cont + 1))
  fi
done
