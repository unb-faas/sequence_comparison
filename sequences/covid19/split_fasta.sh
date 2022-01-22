while IFS= read -r line; do
    if [ "$(echo ${line} | grep '>')" != "" ];then
        file="selected/$(echo $line | sed -e 's/ //g' | sed -e 's/\>//g' | awk -F/ '{print $1}').fasta"
        touch $file
        echo $line >> $file
    else
        if [ "${line}" == "" ];then
            echo $buffer >> $file
            buffer=""
        else
            buffer="${buffer}${line}"
        fi
    fi
done < spike_protein_s_ncbi.fasta