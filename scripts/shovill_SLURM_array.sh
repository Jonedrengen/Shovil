#!/bin/bash
#SAMPLELIST
samplelist_input=$1


#REMOVE EXTENSIONs
samplelist_filename=$(basename "${samplelist_input%%.*}")

#SLURM_ARRAY SPECIFICATIONS (max size, batch index and job index)
slurm_array_maxsize=1000
i=0
j=1

#Initalize array job file and grep R1 files from sample list
> "${samplelist_filename}_SLURM-ARRAY-READY.txt"

#grep R1s
grep "_R1" "$samplelist_input" > "${samplelist_filename}_R1s.txt"
echo "found: $(wc -l < "${samplelist_filename}_R1s.txt") R1 files using '_R1' as identifier"
echo "total: $(wc -l < "$samplelist_input") files in the sample list"
echo


#create indices and append to samplelist
while read -r line;
do
    R1=${line}
    R2="${R1/_R1_/_R2_}"
    str="${i}__@__${j}__@__${R1}__@__${R2}"
    echo "$str" >> "${samplelist_filename}_SLURM-ARRAY-READY.txt"
    if [ $j -lt $slurm_array_maxsize ]
    then
        ((j+=1))
    else
        ((i+=1))
        j=1
    fi
done < "${samplelist_filename}_R1s.txt"

echo "cleaning up intermediate files"
rm -f "${samplelist_filename}_R1s.txt"
