import docker
import argparse
import time
import ftplib
from tqdm import tqdm
import subprocess
import os
import re
import pandas as pd
from datetime import datetime
import sys

model_support_list = ["llama2", "qwen", "llama3.1", "llava"]

model_table = ""

chip_table = {"0": "0,1",
              "1": "2,3",
              "2": "4,5",
              "3": "6,7",
              "4": "8,9",
              "5": "10,11",
              "6": "12,13",
              "7": "14,15",}

def para_prase():
    parser = argparse.ArgumentParser(description='device used')
    parser.add_argument('--dev', type=int, default=0, help='type int')
    parser.add_argument('--models', type=str, nargs='+', default=["llama", "qwen"], help="The models will be tested")
    parser.add_argument('--mode', type=int, nargs='+', default=[1, 0], help="The modes that will be tested")
    parser.add_argument('--data', type=str,  default="/home/wy/text-generation-inference/datasets", help="Storage path of models")

    args = parser.parse_args()

    if not os.path.exists(args.data):
        print(f"Data path does not exist: {args.data}")
        exit()
    else:
        print(f"Data path exist: {args.data}")

    return args

def is_port_in_use(port):
    """Check whether the specified port is occupied"""
    try:
        # Use the 'Ss' command to check the port
        result = subprocess.run(['ss', '-tuln'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        # Traverse each line of the output and check the port
        for line in result.stdout.splitlines():
            if f':{port}' in line:
                return False
    except Exception as e:
        print(f"Error detecting port: {e}")
    return True


def get_daily_build():
    username = "AI"
    passwd = "SophgoRelease2022"
    host = "172.28.141.89"
    path_to_tgi = "/LLMs/text-generation-inference/daily_build/latest_release"

    ftp = ftplib.FTP(host)
    ftp.login(username, passwd)
    ftp.cwd(path_to_tgi)

    files = ftp.nlst()

    for file in files:
        if "docker-soph_tgi-" in file:
            docker_file = file

    if docker_file:
        file_size = ftp.size(docker_file)

        with tqdm(total=file_size, unit='B', unit_scale=True, desc=docker_file) as progress_bar:
            def progress_callback(data):
                progress_bar.update(len(data))
                f.write(data)

            with open("./" + docker_file, 'wb') as f:
                ftp.retrbinary(f"RETR {docker_file}", progress_callback)

    else:
        print("Cannot find docker image file")

    ftp.quit()

    return docker_file

def load_images(docker_file):
    cmd = "bunzip2 -c " + docker_file + " | docker load"
    status, res = subprocess.getstatusoutput(cmd)
    if status == 0:
        print("Loading image executed successfully!")
    else:
        print("Loading image failed!")

    return 0
    
def build_test_container(idx,args):
    home_dir = os.path.expanduser("~/")
    client = docker.from_env()

    try:
        container = client.containers.get("tgi_daily_test_"+str(idx))
        print("Container tgi already exists. Remove and rebuild it...")
        container.stop()
        container.remove()

    except docker.errors.NotFound:
        print("Container tgi does not exist. Creating a new one...")

    finally:
        port = int("1808"+str(idx))
        for i in range(10000):
            if is_port_in_use(port):
                print(f"Port {port} available!")
                break
            elif i != 9999:
                print(port," is used ")
                port+=1
            else:
                print("No ports available!")
                exit()
        container = client.containers.run(
            image="soph_tgi:0.2-slim",
            name="tgi_daily_test_"+str(idx),
            detach=True,
            tty=True,
            privileged=True,
            ports={"80": str(port)},
            volumes={
                "/opt": {"bind": "/opt", "mode": "rw"},
                "/dev": {"bind": "/dev", "mode": "rw"},
                args.data: {"bind": "/data", "mode": "rw"},
            },
            entrypoint="bash"
        )

    return 0

def build_test_env(args):
    docker_file = get_daily_build()
    load_images(docker_file)
    container_names = []
    for i in range(1):
        build_test_container(i,args)
        container_names.append("tgi_daily_test_"+str(i))
    return docker_file, container_names

def test_run(input_len, output_len, tp, model, batch, model_path, is_multi_chip, dev):
    if (is_multi_chip):
        # env_vars = {"TPU_CACHE_HOST_BATCH": "5"}
        # env_vars = "export CHIP_MAP=" +  "0,1,5,3,7,6,2,4 "  + " && export TPU_CACHE_HOST_BATCH=5"
        env_vars = "export CHIP_MAP=" +  chip_table[str(dev)]  + " && export TPU_CACHE_HOST_BATCH=5 && export DEVID=" +  str(dev)
        cmd = "CONTEXT_LEN=" + str(input_len) + " DECODE_TOKEN_LEN=" + str(output_len) + " python3 " + "/usr/src/server/tests/soph_test/test_whole_model.py --model \
" + model + " --batch " + str(batch) + " --path " + model_path
        cmd = env_vars + " && " + cmd
    else:
        env_vars = "export CHIP_MAP=" +  chip_table[str(dev)]  + " && export TPU_CACHE_HOST_BATCH=5 && export DEVID=" +  str(dev)
        cmd = "CONTEXT_LEN=" + str(input_len) + " DECODE_TOKEN_LEN=" + str(output_len) + " torchrun --nproc_per_node " + str(tp) + " --nnodes 1 \
    /usr/src/server/tests/soph_test/test_whole_parallel.py --model " + model +" --quantize gptq"+ " --batch " + str(batch) + " --path " + model_path
        cmd = env_vars + " && " + cmd
    
    print(cmd)
    client = docker.from_env()
    container = client.containers.get("tgi_daily_test_"+str(dev))

    if container.status != "running":
        print(f"Starting container {'tgi_daily_test'}...")
        container.start()
    
    exit_code, output = container.exec_run(f"/bin/bash -c '{cmd}'", tty=True)

    output = output.decode("utf-8")

    # exit_code = 1
    # Check the exit code
    if exit_code != 0:
        print(f"Command execution failed, exit code: {exit_code}")
        print(f"Error output:\n{output}")
        sys.exit(exit_code)  # Pass the Docker exit code


    ansi_escape = re.compile(r'\x1b\[.*?m')
    clean_output = ansi_escape.sub('', output)


    return clean_output

def data_clean(data):

    data_l = data.split("\n")
    ftl, tps, res_content = -1, -1, "FAILED!"
    # print(data_l)
    # pattern = r"FTL:\s*([\d.]+)ms,\s*TPS:\s*([\d.]+)"
    ftl_tps_pattern = r"FTL:\s*([\d.]+)ms,\s*TPS:\s*([\d.]+)"
    res_pattern = r"rank: 0, Batch 0:\s*(.+)"
    for line in data_l:
        print(line)
        ftl_tps_match = re.search(ftl_tps_pattern, line)
        if ftl_tps_match:
            ftl = float(ftl_tps_match.group(1))
            tps = float(ftl_tps_match.group(2))

        batch_match = re.search(res_pattern, line)
        if batch_match:
            res_content = batch_match.group(1)
            
    print(">>>>>>> test completed >>>>>>>")
    print(f"FTL: {ftl}, TPS: {tps}, ANS: {res_content}")
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

    return ftl, tps, res_content

def data_save(ftl, tps, res, model, date, input_len, output_len, batch, dev):
    results = []
    results.append({"MODEL": model, "TEST_TIME": date, "input_len": input_len, "output_len": output_len, "batch": batch,"FTL (ms)": ftl, "TPS": tps, "RES": res})
    df = pd.DataFrame(results)
    csv_name = "test_result/output_"+ model + "_" + str(dev) + ".csv"
    df.to_csv(csv_name, mode='a', index=False, header=not pd.io.common.file_exists(csv_name))

    try:
        xlsx_name = "test_result/output_"+ model + "_" + str(dev) + ".xlsx"
        with pd.ExcelWriter(xlsx_name, engine='openpyxl', mode='a', if_sheet_exists='overlay') as writer:
            # try:
            existing_data = pd.read_excel(xlsx_name, sheet_name=0)
            startrow = len(existing_data) + 1
            # except FileNotFoundError:
            #     startrow = 0
            df.to_excel(writer, index=False, header=startrow == 0, startrow=startrow)
    except FileNotFoundError:
        df.to_excel(xlsx_name, index=False)
    
    
    return

def daily_test(args):

    input_len = [32]
    output_len = [32]
    tp = 2
    model = args.models
    mode = args.mode
    #batch = [1,4,8,16,32]
    batch = [1,4]
    model_path = "/data"
    for item in range(len(model)):
        for i in range(len(output_len)):
            for j in range(len(input_len)):
                for k in range(len(batch)):
                    res = test_run(input_len[j], output_len[i], tp, model[item], batch[k], model_path, mode[item], args.dev)
                    ftl, tps, res = data_clean(res)
                    current_time = datetime.now()
                    formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S")
                    data_save(ftl, tps, res, model[item], formatted_time, input_len[j], output_len[i], batch[k], args.dev)
                    time.sleep(5)

def docker_clean(docker_file,container_names):

    try:
        # Get the current working directory
        current_directory = os.getcwd()
        # Create the full file path
        file_path = os.path.join(current_directory, docker_file)
        
        # Check if the file exists and delete it
        if os.path.isfile(file_path):
            os.remove(file_path)
            print(f"File {docker_file} has been deleted.")
        else:
            print(f"File {docker_file} does not exist.")
    
    except Exception as e:
        print(f"Error while deleting the file: {e}")

    try:
        for container_name in container_names:
            # stop container
            subprocess.run(["docker", "stop", container_name], check=True)
            print(f"container {container_name} stop ")
            
            # clean container
            subprocess.run(["docker", "rm", container_name], check=True)
            print(f"container {container_name} clean ")
        
    except subprocess.CalledProcessError as e:
        print(f"container clean error: {e}")

    # Create a Docker client
    client = docker.from_env()
    # Get all images
    images = client.images.list()
    # Iterate through images and remove dangling images
    for image in images:
        if image.tags == []:  # Check if the image has no tags
            try:
                print(f"Removing image {image.id}...")
                client.images.remove(image.id, force=True)
                print(f"Removed image {image.id}")
            except Exception as e:
                print(f"Error removing image {image.id}")


if __name__=="__main__":
    
    start_time = time.time()
    args = para_prase()
    docker_file, container_names = build_test_env(args)
    print("current dev is " + str(args.dev))
    daily_test(args)
    docker_clean(docker_file, container_names)
    print("all time:",time.time()-start_time)

    
