#!/bin/bash

function help() {
    echo "https://raw.githubusercontent.com/ayufan-rock64/android-7.1/master/Jenkinsfile"
    echo "https://github.com/rock64-android/"
    echo "https://github.com/rock64-android/manifests/commit/0ed10b85d7261254cf2dc0bf58e4f01fd36e8f4e#diff-c17ea3629d72fe625f709e1e054f9fd9"
    ##git log rock64_nougat.xml
    #[Added Rock64 Repo Manifest as seperate file](https://github.com/rock64-android/manifests/commit/0ed10b85d7261254cf2dc0bf58e4f01fd36e8f4e#diff-c17ea3629d72fe625f709e1e054f9fd9)
    #https://blog.csdn.net/QQ2010899751/article/details/81347599
}

function lvm_extent() {
    sudo lvextend -L +1000G /dev/mapper/ubuntu--vg-ubuntu--lv
    sudo resize2fs -p /dev/mapper/ubuntu--vg-ubuntu--lv
}

#ls -al .repo
#manifest.xml - >manifests/default.xml

function set_proxy() {
    git config --global http.proxy 'http://127.0.0.1:8107'
    git config --global https.proxy 'http://127.0.0.1:8107'
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}

function env_set() {
    sudo apt -y install repo
    sudo apt-get install -y openjdk-8-jdk python git-core gnupg flex bison gperf build-essential \
        zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
        lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
        libgl1-mesa-dev libxml2-utils xsltproc unzip mtools u-boot-tools \
        htop iotop sysstat iftop pigz bc device-tree-compiler lunzip \
        dosfstools vim-common

    update-alternatives --config java
    update-alternatives --config javac
}

function reposync() {
    if [ ! -d rock64 ]; then
        mkdir rock64
    fi

    cd rock64

    if [ ! -f repo ]; then
        curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo
        chmod 755 repo
    fi
    git config --global user.email xxx163@163.com
    git config --global user.name xxx163

    export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo/'
    ./repo init -u https://aosp.tuna.tsinghua.edu.cn/platform/manifest -b android-7.1.2_r6 --depth=1 --platform=auto

    cd .repo

    rm -rf rock64_nougat.xml
    #git clone https://github.com/rock64-android/manifests -b default .repo/local_manifests1
    wget https://raw.githubusercontent.com/rock64-android/manifests/default/rock64_nougat.xml
    sed -i "s/android.googlesource.com/aosp.tuna.tsinghua.edu.cn/g" rock64_nougat.xml
    mv manifest.xml manifest.xml.bak.xml
    ln -s rock64_nougat.xml manifest.xml
    cd ..
    time ./repo sync -n -c -j8 --force-sync --no-clone-bundle --force-broken
    cd ..
}

function syncnet() {
    pwd
    if [ ! -d rock64 ]; then
        reposync
    else
        cd rock64
        time ./repo sync -n -c -j8 --force-sync --no-clone-bundle
    fi
}

function sync2local() {
    pwd
    if [ ! d rock64 ]; then
        mkdir rock64
    fi
    cd rock64
    read -t 10 -p "do you really want to clean local and rerepo to local,yes or no,[Y/N]?" answer
    if [ -z $answer ]; then
        echo ""
        echo "timeout for choice"
        answer=timeout
    fi
    case $answer in
    Y | y)
        echo "answer is: yes"
        #rm -rf `ls | grep -v .repo` .classpath
        time ./repo sync -l -c -j8 --force-sync --no-clone-bundle
        ;;
    N | n | timeout | *)
        echo "answer is: $answer"
        time ./repo sync -l -c -j8 --force-sync --no-clone-bundle
        ;;
    esac
    cd ..
}

function build_envset() {
    rm -rf ~/.jack-settings
    rm -rf ~/.jack-server
    cd rock64
    export LC_ALL=C
    export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx6g"
    cd prebuilts/sdk/tools/
    ./jack-admin install-server jack-launcher.jar jack-server-4.8.ALPHA.jar
    cd -
    ./prebuilts/sdk/tools/jack-admin kill-server
    ./prebuilts/sdk/tools/jack-admin start-server
    cd ..
    pwd
}

function build_comile() {
    if [ ! -d out ]; then
        mkdir out
    fi
    cd rock64
    export LC_ALL=C
    time source build.sh
}

function usage() {
    echo ""
    echo "Usage:$0 { env | reposync | syncnet | synclocal | build | * }"
    echo "rock64 android source download and comile"
    echo "env :install some software."
    echo "reposync:     download rock64 android 7.1 source code"
    echo "syncnet:      repo download code from network."
    echo "synclocal:    repo code from repo git lib to local."
    echo "build:        build from source."
    echo "step one by one:"
    echo "sudo ./rock64_repo.sh env"
    echo "./repo_repo.sh syncnet"
    echo "./repo_repo.sh synclocal"
    echo "./repo_repo.sh build"
    echo "or just"
    echo "./repo_rock64.sh all"
    echo ""
    help
}

case $1 in
env)
    echo "set environment"
    env_set
    ;;
reposync)
    echo "repo get package."
    reposync
    ;;
syncnet)
    echo "sync from network"
    syncnet
    ;;
synclocal)
    echo "sync from .repo to local."
    sync2local
    ;;
build_env)
    echo "build environment set"
    build_envset
    ;;
build)
    echo "build"
    build_envset
    build_comile
    ;;
all)
    echo "all"
    env_set
    reposync
    sync2local
    build_envset
    build_comile
    ;;
*)
    usage
    ;;
esac
