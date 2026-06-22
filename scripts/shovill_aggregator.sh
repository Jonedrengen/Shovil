#!/bin/bash
#SBATCH -J shovill_aggregator_%j
#SBATCH --error=shovill_aggregator_%A_%a.err
#SBATCH --output=shovill_aggregator_%A_%a.out
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

#link all 

#TIMER END
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"