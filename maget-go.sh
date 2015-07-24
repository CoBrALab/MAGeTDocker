#!/bin/bash
set -e

if [[ -z "$1" ]];
then
    echo "Error number of processes not specified, please invoke with \"maget-go.sh <NCPUS>\""
    exit 1
fi

mkdir -p /maget/preprocess_input
mkdir -p /maget/preprocess_working

echo "On your local computer (i.e. not in this container) please place all input MINC files into <WORKING_DIRECTORY>/preprocess_input"
read -p "When ready, press any key to continue... " -n1 -s

bpipe run -n $1 -d /maget/preprocess_working /minc-bpipe-library/pipeline.bpipe /maget/preprocess_input/*.mnc

cd /maget
mb init

for file in /maget/preprocess_input/*.mnc
do
    cp /maget/preprocess_working/$(basename $file .mnc).mincconvert.n4correct.cutneckapplyautocrop.mnc /maget/input/subjects/brains
done

echo "Preprocessing complete, all preprocessed subjects can now be found in <WORKING_DIRECTORY>/input/subjects/brains"
echo "Please copy 21 subjects from <WORKING_DIRECTORY>/input/subjects/brains into <WORKING_DIRECTORY>/input/templates/brains for template selection"
echo "Please copy atlases and atlas label files into <WORKING_DIRECTORY>/input/atlases/brains and <WORKING_DIRECTORY>/input/atlases/labels respectively"
read -p "When ready, press any key to continue... " -n1 -s

echo "Running MAGeT Stage 1"
mb run -q parallel --processes $1 register

echo "Running MAGeT Stage 2"
mb run -q parallel --processes $1 vote

echo "MAGeT Complete, label files can be found in <WORKING_DIRECTORY>/output/fusion/majority_vote"
