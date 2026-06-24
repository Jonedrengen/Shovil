#!/bin/bash
#SBATCH -J shovill_runner
#SBATCH --error=shovill_runner_%A_%a.err
#SBATCH --output=shovill_runner_%A_%a.out
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=01:00:00
#SBATCH --partition=project
set +x
#TIMER START
STARTTIMER="$(date +%s)"

#INPUT
Data_Folder_input=$1
Data_Folder_Samplelist_SLURM_ARRAY_READY_input=$2
index_set=$3
main_output_folder_input=$4

#CONFIG
config="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/shovill/Shovil/scripts/config.env"

#CONDA
conda_source="$(grep 'conda_source' "$config" | awk -F'=' '{print $2}' | xargs)"
conda_env_name="$(grep 'conda_env_name' "$config" | awk -F'=' '{print $2}' | xargs)"

. "$conda_source"
conda activate "$conda_env_name"

#INPUT
R1="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${index_set}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $3}')"
R2="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${index_set}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $4}')"


#RUN
echo "Running shovill on $Data_Folder_input"
shovill --outdir "$main_output_folder_input/processing_files/${R1%%.*}" --R1 "$Data_Folder_input/$R1" --R2 "$Data_Folder_input/$R2"

# Create sample folder for outputs
mkdir -p "$main_output_folder_input/processing_files/${R1%%.*}/slurm_outputs"

#MOVING SLURM OUT/ERR
mv "shovill_runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.err" "$main_output_folder_input/processing_files/${R1%%.*}/slurm_outputs"
mv "shovill_runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out" "$main_output_folder_input/processing_files/${R1%%.*}/slurm_outputs"


#TIMER END
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
set -x