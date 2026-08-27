#!/bin/bash 


########################################
############# functions ##############
########################################

help() {
    echo "Usage: $0 -i <input_dir> -o <output_dir> -c <config_file>"
    echo "  -i <input_dir>      : Path to the input directory containing R1 and R2 files"
    echo "  -o <output_dir>     : Path to the output directory where results will be stored"
    echo "  -c <config_file>    : Path to the configuration file (config_template.env)"
    echo "  -h                  : Display this help message"
}

validate_input() {
    local input_dir="$1"
    local output_dir="$2"
    local config_file="$3"

    if [ ! -d "$input_dir" ]; then
        echo "Error: Input folder does not exist: $input_dir"
        exit 1
    fi
    if [ -z "$output_dir" ]; then
        echo "Error: Output directory is not specified"
        exit 1
    fi
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file does not exist: $config_file"
        exit 1
    fi
}

load_config_values() {
    local config_file="$1"
    conda_source_path=""
    conda_env_name=""
    project_clone_path=""
    mode=""
    cpus=""
    mem=""
    partition=""
    shovill_separator=""

    # Load configuration values from config_template.env
    conda_source_path=$(grep '^conda_source_path=' "$config_file" | awk -F'=' '{print $2}')
    conda_env_name=$(grep '^conda_env_name=' "$config_file" | awk -F'=' '{print $2}')
    project_clone_path=$(grep '^project_clone_path=' "$config_file" | awk -F'=' '{print $2}')
    mode=$(grep '^mode=' "$config_file" | awk -F'=' '{print $2}')
    cpus=$(grep '^cpus=' "$config_file" | awk -F'=' '{print $2}')
    mem=$(grep '^mem=' "$config_file" | awk -F'=' '{print $2}')
    partition=$(grep '^partition=' "$config_file" | awk -F'=' '{print $2}')
    job_name=$(grep '^job_name=' "$config_file" | awk -F'=' '{print $2}')
    shovill_separator=$(grep '^shovill_separator=' "$config_file" | awk -F'=' '{print $2}')

    # inform the user about the defined configuration values
    printf "defined conda_source_path: %s\n" "$conda_source_path"
    printf "defined conda_env_name: %s\n" "$conda_env_name"
    printf "defined project_clone_path: %s\n" "$project_clone_path"
    printf "defined mode: %s\n" "$mode"
    printf "defined cpus: %s\n" "$cpus"
    printf "defined mem: %s\n" "$mem"
    printf "defined partition: %s\n" "$partition"
    printf "defined job_name: %s\n" "$job_name"
    printf "defined shovill_separator: %s\n" "$shovill_separator"
    
    echo "______________________________________________________________"
    echo "INFO: if any of the above values are empty, please check your config_template.env file."
    echo
}

activate_conda_env() {
    local conda_source_path="$1"
    local conda_env_name="$2"

    if [ ! -f "$conda_source_path" ]; then
        echo "Error: no source path: $conda_source_path"
        exit 1
    fi
    if [ -z "$conda_env_name" ]; then
        echo "Error: no conda env name specified"
        exit 1
    fi

    # source and activate
    . "$conda_source_path"
    conda activate "$conda_env_name"
}

create_output_structure() {
    local output_folder="$1"
    
    mkdir -p "$output_folder"
    mkdir -p "$output_folder/processing_files"
    mkdir -p "$output_folder/compiled_files"
    mkdir -p "$output_folder/slurm_output"
}

#create list of unique ids based on input folder, because we need 1 folder for each paired read set
create_unique_ID_list() {
    local input_dir="$1"
    local output_dir="$2"
    local separator="$3"
    local unique_ID_file="$output_dir/unique_ID_list.txt"
    local R1_files
    local ID

    touch "$unique_ID_file"
    #finding ids based on on foward read (R1)
    R1_files=$(find "$input_dir" -maxdepth 1 -type f -name "*${separator}1*")
    #send ids to file
    for file in $R1_files; do
        ID=$(basename "$file" | sed "s/${separator}1.*//")
        printf "%s\n" "$ID" >> "$unique_ID_file"
    done

    echo "INFO: $(cat "$unique_ID_file" | wc -l) total lines in $unique_ID_file"
}

#create tsv file: sample_ID, path/to/R1, path/to/R2
create_ID_PATH_list() {
    local input_dir="$1"
    local output_dir="$2"
    local unique_ID_file="$3"
    local separator="$4"
    local tsv_file="$output_dir/sample_list.tsv"
    local ID
    local R1_path
    local R2_path

    if [ ! -f "$unique_ID_file" ]; then
        echo "Error: Unique ID file does not exist: $unique_ID_file"
        exit 1
    fi

    while read -r ID; do
        R1_path=$(find "$input_dir" -maxdepth 1 -type f -name "${ID}${separator}1*")
        R2_path=$(find "$input_dir" -maxdepth 1 -type f -name "${ID}${separator}2*")
        printf "%s\t%s\t%s\n" "$ID" "$R1_path" "$R2_path" >> "$tsv_file"
    done < "$unique_ID_file"

    echo "INFO: $(cat "$tsv_file" | wc -l) total lines in $tsv_file"
}

#create shovill command for each sample in the sample list
create_shovill_commands_file() {
    local sample_list="$1"
    local output_dir="$2"
    local shovill_cmds_file="$output_dir/shovill_commands.txt"
    local shovill_output_dir="$output_dir/processing_files"
    local ID
    local R1_path
    local R2_path

    while read -r line; do
        ID=$(echo "$line" | cut -f1)
        R1_path=$(echo "$line" | cut -f2)
        R2_path=$(echo "$line" | cut -f3)
        printf "shovill --R1 %s --R2 %s --outdir %s/%s\n" "$R1_path" "$R2_path" "$shovill_output_dir" "$ID" >> "$shovill_cmds_file"
    done < "$sample_list"

    echo "INFO: $(cat "$shovill_cmds_file" | wc -l) total lines in $shovill_cmds_file"
}

# create the parallel command to run shovill commands in parallel
create_shovill_command_parallel() {
    local shovill_cmds_file="$1"
    local num_threads="$2"
    local cmd=()
    cmd=(parallel -j "$num_threads" :::: "$shovill_cmds_file")
    echo "${cmd[@]}"
}

#wraps a cmd in a slurm cmd and submits it to slurm
run_cmd_via_slurm() {
    local input_cmd="$1"
    local cpus="$2"
    local mem="$3"
    local partition="$4"
    local job_name="$5"
    local slurm_output_dir="$6"

    sbatch --job-name="$job_name" \
           --cpus-per-task="$cpus" \
           --mem="$mem" \
           --partition="$partition" \
           --output="$slurm_output_dir/${job_name}_%j.out" \
           --error="$slurm_output_dir/${job_name}_%j.err" \
           --wrap="$input_cmd"
}

#symlinks all fasta files in the output folder to a single folder for downstream analysis
aggregate_fasta_files_with_symlink() {
    local processing_files_input_folder="$1"
    local output_folder="$2"
    local fasta_file=""
    local fasta_file_new_name=""
    local counter=0

    for folder in "$processing_files_input_folder"/*; do
        ((counter++))
        fasta_file=$(find "$folder" -type f -name "*.fa")
        fasta_file_new_name=$(basename "$folder")
        
        if [ ! -f "$fasta_file" ]; then
            echo "No fasta file found in $folder"
            continue
        else
            ln -s "$fasta_file" "$output_folder/$(basename "$fasta_file_new_name").fa"
        fi  
    done
    
    echo "Processed $counter folders."
    echo "Generated $(find "$output_folder" -type l -name "*.f*" | wc -l) symlinks in $output_folder"
}

move_slurm_stderr_stdout() {
    local slurm_output_folder="$1"
    local slurm_err_file="$2"
    local slurm_out_file="$3"
        mv -f "$slurm_err_file" "$slurm_output_folder/"
        mv -f "$slurm_out_file" "$slurm_output_folder/"
}



#######################################
############# run script ##############
#######################################

input_dir=""
output_dir=""
config_file=""
while getopts "i:o:c:h:" opt; do
    case $opt in 
        h) help; exit 0 ;;
        i) input_dir="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        c) config_file="$OPTARG" ;;
        *) help; exit 1 ;;
    esac
done
if [ $# -lt 3 ]; then
    help 
    exit 1
fi

validate_input "$input_dir" "$output_dir" "$config_file"

load_config_values "$config_file"

activate_conda_env "$conda_source_path" "$conda_env_name"

create_output_structure "$output_dir"

create_unique_ID_list "$input_dir" "$output_dir" "$shovill_separator"

create_ID_PATH_list "$input_dir" "$output_dir" "$output_dir/unique_ID_list.txt" "$shovill_separator"

create_shovill_commands_file "$output_dir/sample_list.tsv" "$output_dir"

parallel_cmd=$(create_shovill_command_parallel "$output_dir/shovill_commands.txt" "$cpus")

#TODO: slurm mode not implemented.
if [ "$mode" == "slurm" ]; then
    echo "INFO: running shovill commands in parallel via slurm with $cpus threads"

    #cmd 1: shovill
    run_cmd_via_slurm "$parallel_cmd" "$cpus" "$mem" "$partition" "$job_name"_shovill "$output_dir/slurm_output"

    #cmd 2: aggregate fasta files with symlink
    aggregate_func_cmd="aggregate_fasta_files_with_symlink \"$output_dir/processing_files\" \"$output_dir/compiled_files\""
    run_cmd_via_slurm "$aggregate_func_cmd" "$cpus" "$mem" "$partition" "$job_name"_aggregate "$output_dir/slurm_output" "$job_name"_shovill


elif [ "$mode" == "local" ]; then
    echo "INFO: running shovill commands in parallel locally with $cpus threads"
    eval "$parallel_cmd"
    aggregate_fasta_files_with_symlink "$output_dir/processing_files" "$output_dir/compiled_files"
else
    echo "Error: Invalid mode specified in config file: $mode"
    exit 1
fi
