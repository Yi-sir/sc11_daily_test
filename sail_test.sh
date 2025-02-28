function judge_ret() {
  if [[ $1 == 0 ]]; then
    echo -e "\033[32m Passed: $2 \033[0m"
    echo ""
  else
    echo -e "\033[31m Failed: $2 \033[0m"
    exit 1
  fi
  sleep 2
}

pushd sophon-sail2/tests

if [! -d "./data"];
then
    mkdir ./data
    pushd data
    python3 -m dfss --url=open@sophgo.com:sophon-sail/SC11/tests/data.tar.gz
    tar xvf data.tar.gz && rm data.tar.gz
    popd
    echo "data downloaded!"
fi

if [! -d "./models"];
then
    mkdir ./models
    pushd models
    python3 -m dfss --url=open@sophgo.com:sophon-sail/SC11/tests/models.tar.gz
    tar xvf models.tar.gz && rm models.tar.gz
    popd
    echo "models downloaded!"
fi

pushd ./Decoder
python3 -m pytest test_Decoder.py
judge_ret $? "test_Decoder of sail_test"
popd

pushd ./Encoder
python3 -m pytest test_Encoder.py
judge_ret $? "test_Encoder of sail_test"
popd

pushd ./Engine
python3 -m pytest test_Engine.py
judge_ret $? "test_Engine of sail_test"
popd

pushd ./Functional
python3 -m pytest test_Functional.py
judge_ret $? "test_Functional of sail_test"
popd

pushd ./Image
python3 -m pytest test_Image.py
judge_ret $? "test_Image of sail_test"
popd

pushd ./Stream
python3 -m pytest test_Stream.py
judge_ret $? "test_Stream of sail_test"
popd

pushd ./Tensor
pythone -m pytest test_Tensor.py
judge_ret $? "test_Tensor of sail_test"
popd

popd

