#!/bin/bash
#SBATCH -J shovill_submitter
#SBATCH --error=shovill_submitter_%j.err
#SBATCH --output=shovill_submitter_%j.out
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --partition=project

#written by Jon Sztuk Slotved (JOSS@ssi.dk)
#date 22062026

#HELP
function usage {
    echo "Usage: $0 -i <input_folder> -s <sample_list> -o <output_dir> [-m <mode>] "
    echo "  -i: Path to the input folder containing sample files (e.g., FASTQ files)"
    echo "  -s: Path to the sample list file (e.g., a text file with sample names)"
    echo "  -o: Path to the output directory where results will be stored"
    echo "  -m: Mode of operation (e.g., 'SLURM' or 'LOCAL'), default = 'SLURM'"
    echo
    echo "isolates should be named in the format: sample_R1.fastq.gz and sample_R2.fastq.gz or sample_R1.fastq and sample_R2.fastq"
    echo "avoid spaces, dots, and special characters in sample names to prevent issues with file handling"
}

#INPUT and SOURCING
while getopts "i:s:o:m" opt; do
  case $opt in
    i) input_folder="$OPTARG" ;;
    s) sample_list="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    m) mode="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done
slurm_script_location="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/shovill/Shovil/scripts"


#INPUT CHECKS
if [ -z "$input_folder" ] || [ -z "$sample_list" ] || [ -z "$output_dir" ]; then
    usage
    exit 1
fi


#CREATE SLURM ARRAY FILE
bash "$slurm_script_location/shovill_SLURM_array.sh" "$sample_list"
samplelist_filename=$(basename "${sample_list%%.*}") # Strip path and extension; array-ready file goes in current dir
if [ ! -f "${samplelist_filename}_SLURM-ARRAY-READY.txt" ]; then
   echo "Error: failed to generate ${samplelist_filename}_SLURM-ARRAY-READY.txt"
   exit 1
fi
echo 
echo

#CREATE FILE SYSTEM
mkdir -p "$output_dir"
mkdir -p "$output_dir/processing_files"
mkdir -p "$output_dir/slurm"
if [ -n "$SLURM_JOB_ID" ]; then
   mv "shovill_submitter_${SLURM_JOB_ID}.out" "$output_dir/slurm"
   mv "shovill_submitter_${SLURM_JOB_ID}.err" "$output_dir/slurm"
fi
mkdir -p "$output_dir/logs"
shovill --version > "$output_dir/logs/shovill_version.log" 2>&1
shovill --check > "$output_dir/logs/shovill_check.log" 2>&1
mv ${samplelist_filename}_SLURM-ARRAY-READY.txt "$output_dir/"

#SLURM ARRAY SETTINGS
slurm_array_ready_file="$output_dir/${samplelist_filename}_SLURM-ARRAY-READY.txt"
numFiles=$(cat "$slurm_array_ready_file" | wc -l) # Total number of jobs
Slurm_MaxArraySize=1000 # Maximum number of tasks allowed in one array job

# Calculate how many array jobs are needed
if (( $numFiles % $Slurm_MaxArraySize == 0 ))
then
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize`
else
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize + 1` # Round up to the next whole number
fi

# Set how many tasks to run at the same time for each array job
if [ $Slurm_chunks == 1 ]
then
   Slurm_CalcRunParallel=12

elif [ $Slurm_chunks == 2 ]
then
   Slurm_CalcRunParallel=6

elif [ $Slurm_chunks == 3 ]
then
   Slurm_CalcRunParallel=4

elif [ $Slurm_chunks == 4 ]
then
   Slurm_CalcRunParallel=3

elif [ $Slurm_chunks == 5 ]
then
   Slurm_CalcRunParallel=2

elif [ $Slurm_chunks == 6 ]
then
   Slurm_CalcRunParallel=2
else
   Slurm_CalcRunParallel=1
fi
#set manually if needed, by removing comment below
#Slurm_CalcRunParallel=10


for ((i=0; i<$Slurm_chunks; i++)); 
do
    index_set=$i

    array_start="$(cat "$slurm_array_ready_file" | grep "^${i}__" | head -1 | awk -F "__@__" '{print $2}')"
    array_end="$(cat "$slurm_array_ready_file" | grep "^${i}__" | tail -1 | awk -F "__@__" '{print $2}')"

    if [ "$mode" == "SLURM" ]; then
        echo "sbatch --array=${array_start}-${array_end}%${Slurm_CalcRunParallel} "$slurm_script_location/shovill_runner.sh" $input_folder $slurm_array_ready_file $index_set $output_dir"
        sbatch --array=${array_start}-${array_end}%${Slurm_CalcRunParallel} "$slurm_script_location/shovill_runner.sh" "$input_folder" "$slurm_array_ready_file" "$index_set" "$output_dir"
    else
        echo "Running in LOCAL mode is not implemented yet. Please use SLURM mode."
        #bash "$slurm_script_location/shovill_runner.sh" "$input_folder" "$slurm_array_ready_file" "$index_set" "$output_dir"
    fi
done

