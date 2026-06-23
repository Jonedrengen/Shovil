#!/bin/bash
#SBATCH -J shovill_aggregator
#SBATCH --error=shovill_aggregator_%A_%a.err
#SBATCH --output=shovill_aggregator_%A_%a.out
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

#link all 
for line in $main_output_folder_input/processing_files;
do
    file_name=${line%%.*}

    echo "linkining $line/"

    #rename TODO

    ln -s "$line/contigs.fa" "$main_output_folder_input/compiled_files/${file_name}.fasta"
done


#move slurm stuff
mv "shovill_aggregator_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.err" "$main_output_folder_input/slurm"
mv "shovill_aggregator_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out" "$main_output_folder_input/slurm"

#TIMER END
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"

set -x