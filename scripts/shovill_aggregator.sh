#!/bin/bash
#SBATCH -J shovill_aggregator
#SBATCH --error=shovill_aggregator_%j.err
#SBATCH --output=shovill_aggregator_%j.out
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=10:00:00
#SBATCH --partition=project

#TIMER START
STARTTIMER="$(date +%s)"

#INPUT
main_output_folder_input=$1

#FILESYSTEM
mkdir -p "$main_output_folder_input/compiled_files"
ls "$main_output_folder_input/processing_files" > "$main_output_folder_input/tmp_folderlist.txt"
echo -e "sample_id\tstatus" > "$main_output_folder_input/logs/run_report.txt"


#LINK to compiled_results
while read -r line;
do
    echo "extracting results from: $line"
    fasta_path="$main_output_folder_input/processing_files/${line}/${line}.fasta"

    if [[ -f "$fasta_path" ]];
    then
        cp "${main_output_folder_input}/processing_files/${line}/${line}.fasta" "$main_output_folder_input/compiled_files"
        echo -e "${line}\tSUCCESS" >> "$main_output_folder_input/logs/run_report.txt"
    else
        echo -e "${line}\tFAILED" >> "$main_output_folder_input/logs/run_report.txt"
    fi
    echo

done < "$main_output_folder_input/tmp_folderlist.txt"

#grep failed assemblies
if grep -q "FAILED" "$main_output_folder_input/logs/run_report.txt";
then
    grep "FAILED" "$main_output_folder_input/logs/run_report.txt" > "$main_output_folder_input/logs/failed_assemblies.txt"
    echo "$(wc -l "$main_output_folder_input/logs/failed_assemblies.txt") assemblies failed."
else
    echo "no failed assemblies found."
fi

#move slurm stuff and.
mv "shovill_aggregator_${SLURM_JOB_ID}.err" "$main_output_folder_input/slurm"
mv "shovill_aggregator_${SLURM_JOB_ID}.out" "$main_output_folder_input/slurm"
mv "$main_output_folder_input/tmp_folderlist.txt" "$main_output_folder_input/logs"

#TIMER END
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
