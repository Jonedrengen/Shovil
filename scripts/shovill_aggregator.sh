#!/bin/bash
#SBATCH -J shovill_aggregator
#SBATCH --error=shovill_aggregator_%j.err
#SBATCH --output=shovill_aggregator_%j.out
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=10:00:00
#SBATCH --partition=project
set +x
#TIMER START
STARTTIMER="$(date +%s)"

#INPUT
main_output_folder_input=$1

#FILESYSTEM
mkdir -p "$main_output_folder_input/compiled_files"
ls "$main_output_folder_input/processing_files" > "$main_output_folder_input/tmp_folderlist.txt"


#LINK to compiled_results
while read -r line;
do
    echo "extracting results from: $line"
    file_name=$(basename "$line")
    full_path="$main_output_folder_input/processing_files/${line}/config.fa"

    if [[ -f "$full_path" ]];
    then
        ln -s "${main_output_folder_input}/processing_files/${line}/contigs.fa" "$main_output_folder_input/compiled_files/${file_name}.fasta"
    else
        echo "could not find fasta:"
        echo "file: $line"
        echo "full_path: $full_path"
    fi
    
done < "$main_output_folder_input/tmp_folderlist.txt"


#move slurm stuff
mv "shovill_aggregator_${SLURM_JOB_ID}.err" "$main_output_folder_input/slurm"
mv "shovill_aggregator_${SLURM_JOB_ID}.out" "$main_output_folder_input/slurm"

#TIMER END
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"

set -x