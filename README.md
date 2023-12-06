# RISC-V 64 bits with LibSPDM on QEMU

This repository is an implementation of LibSPDM inside QEMU and Das U-Boot especifically for RISC-V 64 bits.

# Compilation Steps

## Initial Configuration

Firstly, initialize the submodules.

```bash
$ git submodules update --init --recursive
```

A specific version of each submodule used was modified, so it's necessary to checkout to different tags and commits.

```bash
# Buildroot
$ cd buildroot
$ git --checkout 2023.08

# U-Boot
$ cd u-boot
$ git --checkout v2023.07

# QEMU
$ cd qemu
$ git --checkout v6.2.0

# LibSPDM
$ cd libspdm
$ git --checkout dc48779a5b8c9199b01549311922e05429af2a0e
```

Now, apply the patches inside the respective folders.

```bash
# U-Boot
$ cd u-boot
$ git am -3 --keep-cr --ignore-space-change patches/u-boot/*.patch

# QEMU
$ cd qemu
$ git am -3 --keep-cr --ignore-space-change patches/qemu/*.patch

# LibSPDM
$ cd libspdm
$ git am -3 --keep-cr --ignore-space-change patches/libspdm/*.patch
```

## LibSPDM

LibSPDM needs to be compiled twice: one to use inside U-Boot and another to use inside QEMU.

```bash
# Build for the host
$ cd libspdm
$ mkdir build_host
$ cmake -DARCH=x64 -DTOOLCHAIN=GCC -DTARGET=Release -DCRYPTO=mbedtls -DGCOV=ON ..
$ make copy_sample_key
$ make
```

```bash
# Build for U-Boot
$ mkdir build_uboot
$ cd build_uboot
$ cmake -DARCH=riscv64 -DTOOLCHAIN=BROOT_RISCV -DTARGET=Release -DCRYPTO=mbedtls ..
$ make
```

## QEMU

Go to `qemu` folder, configure and compile it.

```bash
$ mkdir build
$ cd build
$ ../configure \
    --target-list=riscv64-softmmu \
    --enable-gtk \
    --enable-system \
    --enable-virtfs \
    --enable-sdl \
    --enable-nettle \
    --disable-pie \
    --enable-debug \
    --disable-werror \
    --enable-jemalloc \
    --enable-slirp \
    --enable-libspdm \
    --libspdm-srcdir=/path/to/libspdm \
    --libspdm-builddir=/path/to/libspdm/build_host \
    --libspdm-crypto=mbedtls \
    --extra-cflags='-fPIC --coverage -fprofile-arcs -ftest-coverage' \
    --extra-ldflags='-lgcov'
$ make
```
## Buildroot, U-Boot, OpenSBI

This repository has a Makefile for it, just run the command to make it all.

```bash
# At workspace
$ make all
```

# Running

To run and test if the VirtIO Block device is being authenticated before booting Linux, first it's needed to create a media disk with the OS.

```bash
$ dd if=/dev/zero of=disk.img bs=1M count=128
$ sudo parted disk.img gpt
$ sudo losetup --find --show disk.img
$ sudo parted --align minimal /dev/loopN mkpart primary ext4 0% 50%
$ sudo parted --align minimal /dev/loopN mkpart primary ext4 50% 100%
$ sudo mkfs.ext4 /dev/loopNp1
$ sudo mkfs.ext4 /dev/loopNp2
$ sudo parted /dev/loopN set 1 boot on
$ sudo mkdir /mnt/boot
$ sudo mkdir /mnt/rootfs
$ sudo mkdir /mnt/buildroot
$ sudo losetup --find --show /path/to/buildroot/output/images/rootfs.ext4

# loopM is returned by losetup 
$ sudo mount /dev/loopM /mnt/buildroot
$ sudo mount /dev/loopNp1 /mnt/boot
$ sudo mount /dev/loopNp2 /mnt/rootfs
$ sudo cp /path/to/buildroot/output/images/Image /mnt/boot
$ sudo cp /mnt/buildroot/* /mnt/rootfs

# Delete directories and release loop devices
$ sudo umount /mnt/boot
$ sudo umount /mnt/rootfs
$ sudo umount /mnt/buildroot
$ sudo losetup -d /dev/loopN
$ sudo losetup -d /dev/loopM
$ sudo rm -rf /mnt/*
```

The command to run the emulation is the following.

```bash
$ cd qemu/build
$ ./riscv64-softmmu/qemu-system-riscv64 \
    -smp 2 \
    -nographic \
    -m 8G \
    -M virt \
    -bios /path/to/opensbi/build/platform/generic/firmware/fw_payload.elf \
    -drive file=/path/to/disk.img,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0
```
