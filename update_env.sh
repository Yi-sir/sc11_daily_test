#!/bin/bash

DAILY_TEST_DIR=$(dirname $(readlink -f "$0"))
DAILY_DEBS_DIR=$DAILY_TEST_DIR/ftp-$(date +'%Y-%m-%d')

HOST_PASSWD='sn123456'

FTP_USER='AI'
FTP_PASSWD='SophgoRelease2022'
FTP_HOST='172.28.141.89'

tpuv7rt_version="*"
sophon_media_version="*"

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

function download() {
    filename=$1
    deb_url=$2
    if [ ! -f $filename ]; then
        echo "Start download file: "$filename
        wget $deb_url
        judge_ret $? "Downloaded "$filename
    else
        echo "File already existed: "$filename", so downloading is skipped!"
    fi
}

function get_latest_debs() {
    local sdk_arch=x86_64
    local sdk_arch_alias=amd64
    local sdk_mode="PCIe"

    local tpuv7_driver_deb_filename=tpuv7-driver_${tpuv7rt_version}_${sdk_arch_alias}.deb
    local tpuv7_driver_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/tpuv7-runtime/daily_build/latest_release/${sdk_mode}/${sdk_arch}/${tpuv7_driver_deb_filename}

    local tpuv7rt_deb_filename=tpuv7-runtime_${tpuv7rt_version}_${sdk_arch_alias}.deb
    local tpuv7rt_dev_deb_filename=tpuv7-runtime-dev_${tpuv7rt_version}_${sdk_arch_alias}.deb
    local tpuv7rt_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/tpuv7-runtime/daily_build/latest_release/${sdk_mode}/${sdk_arch}/${tpuv7rt_deb_filename}
    local tpuv7rt_dev_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/tpuv7-runtime/daily_build/latest_release/${sdk_mode}/${sdk_arch}/${tpuv7rt_dev_deb_filename}

    local libsophav_deb_filename=sophon-media-libsophav_${sophon_media_version}_${sdk_arch_alias}.deb
    local libsophav_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon_media/daily_build/latest_release/${libsophav_deb_filename}
    local libsophav_dev_deb_filename=sophon-media-libsophav-dev_${sophon_media_version}_${sdk_arch_alias}.deb
    local libsophav_dev_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon_media/daily_build/latest_release/${libsophav_dev_deb_filename}

    local sophon_ffmpeg_deb_filename=sophon-media-sophon-ffmpeg_${sophon_media_version}_${sdk_arch_alias}.deb
    local sophon_ffmpeg_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon_media/daily_build/latest_release/${sophon_ffmpeg_deb_filename}
    local sophon_ffmpeg_dev_deb_filename=sophon-media-sophon-ffmpeg-dev_${sophon_media_version}_${sdk_arch_alias}.deb
    local sophon_ffmpeg_dev_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon_media/daily_build/latest_release/${sophon_ffmpeg_dev_deb_filename}

    local sophon_opencv_deb_filename=sophon-media-sophon-opencv_${sophon_media_version}_${sdk_arch_alias}.deb
    local sophon_opencv_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon_media/daily_build/latest_release/${sophon_opencv_deb_filename}
    local sophon_opencv_dev_deb_filename=sophon-media-sophon-opencv-dev_${sophon_media_version}_${sdk_arch_alias}.deb
    local sophon_opencv_dev_deb_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon_media/daily_build/latest_release/${sophon_opencv_dev_deb_filename}

    if [ ! -d $DAILY_DEBS_DIR ]; then
        mkdir -p $DAILY_DEBS_DIR
    fi

    rm -rf $DAILY_DEBS_DIR/*

    pushd $DAILY_DEBS_DIR

    download $tpuv7_driver_deb_filename $tpuv7_driver_deb_url

    download $tpuv7rt_deb_filename $tpuv7rt_deb_url
    download $tpuv7rt_dev_deb_filename $tpuv7rt_dev_deb_url

    for file in $tpuv7_driver_deb_filename; do
        if [[ -f $file ]]; then
            # 提取版本号
            if [[ $file =~ tpuv7-driver_([0-9]+\.[0-9]+\.[0-9]+)_${sdk_arch_alias}\.deb ]]; then
                tpuv7rt_version=${BASH_REMATCH[1]}
                echo "File: $file"
                echo "Version: $tpuv7rt_version"
            else
                echo "Version not found in file name: $file"
            fi
        else
            echo "No file found matching the pattern: $tpuv7_driver_deb_filename"
        fi
    done

    download $libsophav_deb_filename $libsophav_deb_url
    download $libsophav_dev_deb_filename $libsophav_dev_deb_url

    download $sophon_ffmpeg_deb_filename $sophon_ffmpeg_deb_url
    download $sophon_ffmpeg_dev_deb_filename $sophon_ffmpeg_dev_deb_url

    download $sophon_opencv_deb_filename $sophon_opencv_deb_url
    download $sophon_opencv_dev_deb_filename $sophon_opencv_dev_deb_url

    for file in $libsophav_deb_filename; do
        if [[ -f $file ]]; then
            # 提取版本号
            if [[ $file =~ sophon-media-libsophav_([0-9]+\.[0-9]+\.[0-9]+)_${sdk_arch_alias}\.deb ]]; then
                sophon_media_version=${BASH_REMATCH[1]}
                echo "File: $file"
                echo "Version: $sophon_media_version"
            else
                echo "Version not found in file name: $file"
            fi
        else
            echo "No file found matching the pattern: $libsophav_deb_filename"
        fi
    done

    popd

    echo -e "\033[32m Downloaded all debs successfully! \033[0m"
}

function check_driver_status() {
    use_count=$(echo $HOST_PASSWD | sudo -S lsmod | grep sgcard | awk '{print $3}')

    echo "use_cout: "$use_count
    
    if [ -z "$use_count" ]; then
        echo "sgcard module not found, goes on."
        return 0
    fi

    if [ "$use_count" -gt 0 ]; then
        echo "The driver is in use. Attempting to stop Docker containers..."
        
        running_containers=$(docker ps -q)
        if [ -n "$running_containers" ]; then
            docker stop $running_containers
        else
            echo "No running Docker containers found."
        fi

        use_count=$(sudo lsmod | grep sgcard | awk '{print \$3}')
        if [ "$use_count" -gt 0 ]; then
            echo "The driver is still in use. Please manually stop all Docker containers and try again!"
            exit 1
        fi
    fi

    echo "sgcard module is not in use. Proceeding..."
}

function check_dmesg_fail() {
    if dmesg -T | tail -n 100 | grep -Eiq "fail|error"; then
        echo "found 'fail' or 'error' in dmesg logs."
        return 1
    else
        echo "No 'fail' or 'error' found in dmesg logs."
        return 0
    fi
}

function install_driver() {
    pushd $DAILY_DEBS_DIR

    check_driver_status

    sudo dpkg -i tpuv7-driver*.deb
    judge_ret $? "Installed tpuv7-driver"

    check_dmesg_fail
    judge_ret $? "Checked dmesg logs"

    popd
}

function install_single_deb() {
    local deb_filename=$1
    pushd $DAILY_DEBS_DIR

    sudo dpkg -i $deb_filename
    judge_ret $? "Installed "$deb_filename

    popd
}

function install_debs() {

    install_driver
    judge_ret $? "Installed driver"

    install_single_deb tpuv7-runtime*.deb
    install_single_deb tpuv7-runtime-dev*.deb

    install_single_deb sophon-media-libsophav*.deb
    install_single_deb sophon-media-libsophav-dev*.deb

    install_single_deb sophon-media-sophon-ffmpeg*.deb
    install_single_deb sophon-media-sophon-ffmpeg-dev*.deb

    install_single_deb sophon-media-sophon-opencv*.deb
    install_single_deb sophon-media-sophon-opencv-dev*.deb

    echo "\033[32m Installed all debs successfully! \033[0m"
}

function get_latest_sail() {
    local sail_version="*"
    local sail_tar_filename=sophon-sail_${sail_version}.tar.gz
    local sail_tar_url=ftp://$FTP_USER:$FTP_PASSWD@$FTP_HOST/sg2260/sophon-sail/daily_build/latest_release/${sail_tar_filename}

    pushd $DAILY_DEBS_DIR
    download $sail_tar_filename $sail_tar_url
    popd
}

function install_sail() {
    source /home/sn/miniconda3/etc/profile.d/conda.sh
    conda activate sail3.10
    pushd $DAILY_DEBS_DIR
    tar -zxvf sophon-sail*.tar.gz
    echo "current tpuv7rt version: $tpuv7rt_version"
    echo "current sophon_media version: $sophon_media_version"
    local sail_wheel_filename=sophon-sail/python_wheels/x86_64_pcie/tpuv7rt-${tpuv7rt_version}_sophon_media-${sophon_media_version}/py310/sophon-0.3.0-py3-none-any.whl
    if [ ! -e "$sail_wheel_filename" ]; then
        echo -e "\033[31m file $sail_wheel_filename does not exist. \033[0m"
        exit 1
    fi
    pip3 install ${sail_wheel_filename} --force-reinstall --no-deps
    judge_ret $? "Installed sohpon-sail"
    rm -rf ./sophon-sail*
    popd
    conda deactivate
}

get_latest_debs
install_debs
get_latest_sail
install_sail

rm -rf $DAILY_DEBS_DIR