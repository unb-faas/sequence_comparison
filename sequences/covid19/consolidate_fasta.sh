for i in $(ls originals); do
    cat originals/${i}
    exit
done


exit


while IFS= read -r line; do
    if [ "$(echo ${line} | grep '>')" != "" ];then
        file=$(echo $line | sed -e 's/ //g' | awk -F/ '{print $1}')
        touch $file
    fi
    echo $line >> $file
done < spike_protein_s_ncbi.fasta