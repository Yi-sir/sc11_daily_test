#!/bin/bash

DAILY_TEST_DIR=$(dirname $(readlink -f "$0"))
ASYNC_TEST_DIR=$DAILY_TEST_DIR/async_test

function get_script_and_model() {
    pip3 install dfss
    python3 -m dfss --url=open@sophgo.com:test/async_test_resnet.tar.gz

    tar zxvf ./async_test_resnet.tar.gz
    rm -f ./async_test_resnet.tar.gz
}

if [ ! -d $ASYNC_TEST_DIR ]; then
    rm -rf  $ASYNC_TEST_DIR
fi



source /home/sn/miniconda3/etc/profile.d/conda.sh
conda activate sail3.10

get_script_and_model

pushd $ASYNC_TEST_DIR

python3 async_test.py

conda deactivate
popd
