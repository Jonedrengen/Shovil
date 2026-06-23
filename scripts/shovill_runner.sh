#!/bin/bash
#SBATCH -J shovill_runner_%a
#SBATCH --error=shovill_runner_%A_%a.err
#SBATCH --output=shovill_runner_%A_%a.out
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --partition=project

#TIMER START
STARTTIMER="$(date +%s)"

#INPUT
Data_Folder_input=$1
Data_Folder_Samplelist_SLURM_ARRAY_READY_input=$2
index_set=$3
main_output_folder_input=$4

#CONDA
conda_source="/users/data/Tools/Conda/Miniconda3-py312_24.11.1-0-Linux-x86_64/etc/profile.d/conda.sh"
. "$conda_source"
conda activate shovill_module

#INPUT
R1="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${index_set}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $3}')"
R2="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${index_set}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $4}')"

# Create sample folder for outputs
mkdir -p "$main_output_folder_input/processing_files/${R1%%.*}"
mkdir -p "$main_output_folder_input/processing_files/${R1%%.*}/slurm_outputs"

#RUN
echo "Running shovill on $Data_Folder_input"
shovill --outdir "$main_output_folder_input/processing_files/$R1" --R1 "$Data_Folder_input/$R1" --R2 "$Data_Folder_input/$R2"

#MOVING SLURM OUT/ERR
mv "shovill_runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.err" "$main_output_folder_input/processing_files/$R1/slurm_outputs"
mv "shovill_runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out" "$main_output_folder_input/processing_files/$R1/slurm_outputs"


#TIMER END
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
