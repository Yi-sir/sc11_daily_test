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
popd

pushd ./Encoder
python3 -m pytest test_Encoder.py
popd

pushd ./Engine
python3 -m pytest test_Engine.py
popd

pushd ./Functional
python3 -m pytest test_Functional.py
popd

pushd ./Image
python3 -m pytest test_Image.py
popd

pushd ./Stream
python3 -m pytest test_Stream.py
popd

pushd ./Tensor
pythone -m pytest test_Tensor.py
popd

popd

