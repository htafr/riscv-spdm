SHELL=/bin/bash
WORKSPACE=$(shell pwd)
NPROC=$(shell nproc)
BIN_DIR=${WORKSPACE}/buildroot/output/host/bin
CC_RISCV64=${BIN_DIR}/riscv64-linux-
SPDM_DIR=${HOME}/riscv/libspdm
SPDM_BUILD_DIR=${SPDM_DIR}/build_uboot
CLEANERS=buildroot-clean opensbi-clean uboot-clean

.PHONY: 
	all clean linux-rebuild opensbi uboot check-cross-compile ${CLEANERS}
	check-uboot

check-uboot:
	@echo "Checking if u-boot.bin exists..."
ifneq ($(wildcard ${WORKSPACE}/u-boot/u-boot.bin),)
	@echo "u-boot.bin exists"
else
	@echo "Error: u-boot.bin wasn't found. Compile u-boot first."; exit 2
endif

check-cross-compile:
	@echo "Checking if cross compiler exists..."
ifneq ("$(wildcard ${CC_RISCV64}*)","")
	@echo "Cross compiler exists"
else
	@echo "Error: riscv64-linux- wasn't found. Compile buildroot first."; exit 2
endif

buildroot: buildroot-clean
	$(MAKE) -C buildroot/ qemu_riscv64_virt_defconfig BR2_JLEVEL=${NPROC}
	$(MAKE) -C buildroot/ BR2_JLEVEL=${NPROC}

linux-rebuild: check-cross-compile
	$(MAKE) -C buildroot/ linux-rebuild BR2_JLEVEL=${NPROC}

uboot: check-cross-compile
	if [ ! -e ${WORKSPACE}/u-boot/.config ] ; then $(MAKE) -C u-boot/ CROSS_COMPILE=${CC_RISCV64} qemu-riscv64_smode_defconfig -j${NPROC}; fi
	$(MAKE) -C u-boot/ CROSS_COMPILE=${CC_RISCV64} SPDM_DIR=${SPDM_DIR} SPDM_BUILD_DIR=${SPDM_BUILD_DIR} -j${NPROC}

opensbi: check-cross-compile check-uboot
	$(MAKE) -C opensbi/ CROSS_COMPILE=${CC_RISCV64} PLATFORM=generic FW_PAYLOAD_PATH=${WORKSPACE}/u-boot/u-boot.bin -j${NPROC}

all: clean buildroot uboot opensbi

buildroot-clean:
	$(MAKE) -C buildroot/ distclean

uboot-clean:
	$(MAKE) -C u-boot/ distclean

opensbi-clean:
	$(MAKE) -C opensbi/ clean

clean: ${CLEANERS}

