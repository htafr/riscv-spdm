#!/bin/bash
unset WORKSPACE NPROC BIN_DIR CC_RISCV64 SPDM_DIR SPDM_BUILD_DIR

export WORKSPACE=$(pwd)
export NPROC=$(nproc)
export BIN_DIR=$WORKSPACE/buildroot/output/host/bin
export CC_RISCV64=$BIN_DIR/riscv64-linux-
export SPDM_DIR=$WORKSPACE/libspdm
export SPDM_BUILD_DIR=$SPDM_DIR/build_uboot
export PATH="$PATH:$WORKSPACE/buildroot/output/host/bin"

if [ `uname -m` == "x86_64" ]
then
    export HOST_ARCH="x64"
else
    export HOST_ARCH=$(uname -m)
fi
