#!/bin/bash
set -eo pipefail

# install Go compiler
sudo rm -r /usr/local/go*

# install Singularity dependencies 
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    wget \
    pkg-config \
    git \
    cryptsetup

export VERSION=1.13 OS=linux ARCH=amd64
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz
rm go$VERSION.$OS-$ARCH.tar.gz
ls -ltra /usr/local
ls -ltra /usr/local/go

echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

export PATH=/usr/local/go/bin:$PATH
echo $(which go)
go version
