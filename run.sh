#!/bin/bash

opt=`echo $1 | awk '{split($0, a, "-"); print a[2]}'`

if [ $opt == "hd" ]
then
  $WORKSPACE/qemu/build/riscv64-softmmu/qemu-system-riscv64 \
    -smp 2 \
    -nographic \
    -m 8G \
    -M virt \
    -bios $WORKSPACE/opensbi/build/platform/generic/firmware/fw_payload.elf \
    -drive file=$WORKSPACE/disk.img,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0
elif [ $opt == "sd" ]
then
  $WORKSPACE/qemu/build/riscv64-softmmu/qemu-system-riscv64 \
    -smp 2 \
    -nographic \
    -m 8G \
    -M virt \
    -bios $WORKSPACE/opensbi/build/platform/generic/firmware/fw_payload.elf \
    -drive file=$WORKSPACE/disk.img,format=raw,id=sd1 \
    -device sd-card,drive=sd1
fi
