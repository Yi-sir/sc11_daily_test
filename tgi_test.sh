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
# mode 0 表示双芯
# test_whole_parallel.py --model:(choose from 'llama2-70b', 'llama2-7b', 'llama3-70b', 'llama3.1-8b', 'qwen2-72b', 'qwen2.5-32b', 'qwen2.5-14b', 'qwen2-7b', 'qwen2-57b-a14b')
# test_whole_model.py --model:(choose from 'llama2-7b', 'llama3.1-8b', 'qwen2.5-32b', 'qwen2.5-14b', 'qwen2-7b', 'qwen2-57b-a14b')

conda_path=/home/xyz/miniconda3/etc/profile.d/conda.sh
forge_path=/home/xyz/miniforge3/etc/profile.d/conda.sh

if [[ -e $conda_path ]]; then
    source $conda_path
else
    source $forge_path
fi
conda activate sail3.10

python3 tgi_test.py --models 'llama2-7b' --mode 1 --data '/workspace/models/' >> "$log_file" 2>&1 || {
    echo "Tgi_test script execution failed, exit!"
    exit 1
}
# python3 tgi_test.py --models 'llama2-7b' 'llama3.1-8b' --mode 1 1 --data '/workspace/models/' >> "$log_file" 2>&1


conda deactivate

popd
