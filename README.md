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
$ git checkout 2023.08

# U-Boot
$ cd u-boot
$ git checkout v2023.07

# QEMU
$ cd qemu
$ git checkout v6.2.0

# LibSPDM
$ cd libspdm
$ git checkout dc48779a5b8c9199b01549311922e05429af2a0e
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

## Configure the environment

To use the Makefile, some environment variables are needed, so run the `env.sh` script.

```bash
$ . ./env.sh
```

## LibSPDM

LibSPDM needs to be compiled twice: one to use inside U-Boot and another to use inside QEMU. The Makefile already does these actions, just run one command.

```bash
$ make libspdm
```

Be aware that, if the architecture you are running is different from x86_64, you may need to change the `-DTOOLCHAIN=GCC` inside Makefile. For instance, I run my experiments also in M1 processor, so the toolchain for me would be `-DTOOLCHAIN=AARCH64_GCC`.

## QEMU

Just execute the make command and it will configure and build QEMU.

```bash
$ make qemu
```
## Buildroot, U-Boot, OpenSBI

This repository has a Makefile for it, just run the command to make it all. There is a configuration file inside `files/u-boot` for U-Boot, it's exactly the configuration I use, just copy it to U-Boot root directory and remember to make it hidden.

```bash
# Copying config file to U-Boot
$ cp files/u-boot/config u-boot/.config

# At workspace
$ make buildroot

# Since U-Boot and OpenSBI are connected in this project, run the following
# command to compile both
$ make payload
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

Now, just run the shell script to run the project.

```bash
$ ./run.sh
```
