#!/bin/bash


Data_Folder_input="$1"
SLURM_array_list="$2"
main_output_folder_input="$3"
config="$4"

#define runner func
run_shovill() {
    local R1="$1"
    local R2="$2"
    local sequenceID
    sequenceID=$(echo "$R1" | awk -F'_R1' '{print $1}')
    shovill --outdir "$main_output_folder_input/processing_files/$sequenceID" --R1 "${Data_Folder_input}/${R1}" --R2 "${Data_Folder_input}/${R2}"
}
#EXPORT for PARALLEL
export Data_Folder_input main_output_folder_input config
export -f run_shovill

#INPUT
threads=$(grep "threads" "$config" | awk -F'=' '{print $2}')

#CONDA
conda_source=$(grep "conda_source" "$config" | awk -F'=' '{print $2}')
conda_env=$(grep "conda_env_name" "$config" | awk -F'=' '{print $2}')
. "$conda_source"
conda activate "$conda_env"

#RUN
parallel -j $threads --colsep '__@__' 'run_shovill {3} {4}' :::: "$SLURM_array_list"

#parallel [options] [command [arguments]] ( ::: arguments | :::+ arguments | :::: argfile(s) | ::::+ argfile(s) ) ...