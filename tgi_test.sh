#!/bin/bash

DAILY_TEST_DIR=$(dirname $(readlink -f "$0"))
TGI_TEST_DIR=$DAILY_TEST_DIR/tgi_test

pushd $TGI_TEST_DIR

# get date
current_date=$(date +'%Y-%m-%d')
# new log name
log_file="./test_result/test_result_$current_date.log"
# verify path
mkdir -p ./test_result
# run tgi_test.py 
# mode 1 表示单芯

conda_path=/home/xyz/miniconda3/etc/profile.d/conda.sh
forge_path=/home/xyz/miniforge3/etc/profile.d/conda.sh

if [[ -e $conda_path ]]; then
    source $conda_path
else
    source $forge_path
fi
conda activate sail3.10

python3 tgi_test.py --models 'llama' --mode 1 --data '/home/xyz/LLM' >> "$log_file" 2>&1
# python3 tgi_test.py --models 'llama' 'qwen' --mode 1 0 --data '/home/xyz/LLM' >> "$log_file" 2>&1

conda deactivate

popd
