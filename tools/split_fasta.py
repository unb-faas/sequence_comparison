# require -> pip3 install biopython
import os
from Bio import SeqIO
from pathlib import Path
def split_fasta(fasta_file, out_dir: Path):
    '''
    Extract multiple sequence fasta file and write each sequence in separate file
    :param fasta_file: Source file with the sequences
    :param out_dir: Directory where the separated files will be writen
    :return: Number of sequences
    '''
    
    print("> Split file: {}".format(fasta_file))
    
    file_count = 0
    
    with open(fasta_file) as FH:
        record = SeqIO.parse(FH, "fasta")
        for seq_rec in record:
            try:
                os.makedirs(out_dir+seq_rec.id.strip())
            except:
                print("") 
            file_output = Path(out_dir, seq_rec.id.strip() + ".fasta")
            file_count = file_count + 1
            # print("\tWriting: {}".format(file_output))
            with open(file_output, "w") as FHO:
                SeqIO.write(seq_rec, FHO, "fasta")
    if file_count == 0:
        raise Exception("No valid sequence in fasta file")
    else:
        print("\n> {} Files created with success.".format(file_count))
        return file_count
        
split_fasta('../sequences/hiv/SGSGenbankFasta_1614265939654.fasta', '../sequences/hiv/splited/')