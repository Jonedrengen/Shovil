#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <sample-list>" >&2
    exit 1
fi

samplelist_input=$1

if [[ ! -f "$samplelist_input" ]]; then
    echo "Error: sample list not found: $samplelist_input" >&2
    exit 1
fi

samplelist_filename=$(basename "$samplelist_input")
samplelist_filename=${samplelist_filename%%.*}
output_file="${samplelist_filename}_SLURM-ARRAY-READY.txt"
temporary_output=$(mktemp "${output_file}.XXXXXX")
trap 'rm -f "$temporary_output"' EXIT

slurm_array_maxsize=1000
batch_index=0
task_index=1
r1_count=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # Accommodate sample lists written with Windows line endings.
    line=${line%$'\r'}

    # Match an R1 marker preceded by _, -, or ., preserving the marker's case.
    # The suffix is retained, so both *_R1.fastq.gz and *_R1_001.fastq.gz work.
    if [[ ! "$line" =~ ^(.+)([_.-])([Rr])1(.*)$ ]]; then
        continue
    fi

    prefix=${BASH_REMATCH[1]}
    separator=${BASH_REMATCH[2]}
    read_letter=${BASH_REMATCH[3]}
    suffix=${BASH_REMATCH[4]}
    r1=$line
    r2="${prefix}${separator}${read_letter}2${suffix}"

    if ! grep -Fxq -e "$r2" "$samplelist_input"; then
        echo "Error: missing R2 mate for $r1; expected $r2" >&2
        exit 1
    fi

    printf '%s__@__%s__@__%s__@__%s\n' \
        "$batch_index" "$task_index" "$r1" "$r2" >> "$temporary_output"

    r1_count=$((r1_count + 1))
    if (( task_index == slurm_array_maxsize )); then
        batch_index=$((batch_index + 1))
        task_index=1
    else
        task_index=$((task_index + 1))
    fi
done < "$samplelist_input"

if (( r1_count == 0 )); then
    echo "Error: no R1 entries found in $samplelist_input" >&2
    exit 1
fi

mv "$temporary_output" "$output_file"
trap - EXIT

echo "found: $r1_count R1 files"
echo "total: $(wc -l < "$samplelist_input") files in the sample list"
