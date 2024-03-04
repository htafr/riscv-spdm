SHELL=/bin/bash
CLEANERS=buildroot-clean opensbi-clean uboot-clean qemu-clean libspdm-clean

.PHONY: 
	all broot clean linux-rebuild opensbi uboot check-cross-compile ${CLEANERS}
	check-uboot payload qemu-config emulator spdm

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

broot:
	if [ -d ${WORKSPACE}/buildroot/output ] ; then echo "Buildroot has an 'output' folder, if you want to force compilation run 'make buildroot-clean' and then 'make buildroot'" && exit 1 ; fi
	$(MAKE) -C buildroot/ qemu_riscv64_virt_defconfig BR2_JLEVEL=${NPROC}
	$(MAKE) -C buildroot/ BR2_JLEVEL=${NPROC}

spdm: check-cross-compile
	if [ ! -d ${SPDM_DIR}/build_host ] ; then mkdir ${SPDM_DIR}/build_host ; fi
	if [ ! -d ${SPDM_BUILD_DIR} ] ; then mkdir ${SPDM_BUILD_DIR} ; fi
	cd ${SPDM_DIR}/build_host ; cmake -DARCH=${HOST_ARCH} -DTOOLCHAIN=GCC -DTARGET=Release -DCRYPTO=mbedtls .. ; make copy_sample_key ; make
	cd ${SPDM_BUILD_DIR} ; cmake -DARCH=riscv64 -DTOOLCHAIN=UBOOT -DTARGET=Release -DCRYPTO=mbedtls .. ; make
	cd ${WORKSPACE}

qemu-config:
	if [ ! -d ${WORKSPACE}/qemu/build ] ; then mkdir ${WORKSPACE}/qemu/build ; fi
	cd ${WORKSPACE}/qemu/build ; ../configure --target-list=riscv64-softmmu --enable-gtk --enable-system --enable-virtfs --enable-sdl --enable-nettle --disable-pie --enable-debug --disable-werror --enable-jemalloc --enable-slirp --enable-libspdm --libspdm-srcdir=${SPDM_DIR} --libspdm-builddir=${SPDM_DIR}/build_host --libspdm-crypto=mbedtls --extra-cflags='-fPIC --coverage -fprofile-arcs -ftest-coverage' --extra-ldflags='-lgcov' ;	cd ${WORKSPACE}

emulator: qemu-config
	cd ${WORKSPACE}/qemu/build ; make -j${NPROC} ; cd ${WORKSPACE}
	if [ ! -e ${WORKSPACE}/ecp384 ] ; then ln -s ${SPDM_DIR}/build_host/bin/ecp384 ; fi
	if [ ! -e ${WORKSPACE}/rsa3072 ] ; then ln -s ${SPDM_DIR}/build_host/bin/rsa3072 ; fi

linux-rebuild: check-cross-compile
	$(MAKE) -C buildroot/ linux-rebuild BR2_JLEVEL=${NPROC}

uboot: check-cross-compile
	if [ ! -e ${WORKSPACE}/u-boot/.config ] ; then $(MAKE) -C u-boot/ CROSS_COMPILE=${CC_RISCV64} qemu-riscv64_smode_defconfig -j${NPROC}; fi
	$(MAKE) -C u-boot/ CROSS_COMPILE=${CC_RISCV64} SPDM_DIR=${SPDM_DIR} SPDM_BUILD_DIR=${SPDM_BUILD_DIR} -j${NPROC}

opensbi: check-cross-compile check-uboot
	$(MAKE) -C opensbi/ CROSS_COMPILE=${CC_RISCV64} PLATFORM=generic FW_PAYLOAD_PATH=${WORKSPACE}/u-boot/u-boot.bin -j${NPROC}

payload:
	$(MAKE) uboot
	$(MAKE) opensbi

all: broot spdm qemu payload

buildroot-clean:
	$(MAKE) -C buildroot/ distclean

uboot-clean:
	$(MAKE) -C u-boot/ distclean

opensbi-clean:
	$(MAKE) -C opensbi/ clean

qemu-clean:
	if [ -d ${WORKSPACE}/qemu/build ] ; then rm -rf ${WORKSPACE}/qemu/build ; fi

libspdm-clean:
	if [ -d ${SPDM_BUILD_DIR} ] ; then rm -rf ${SPDM_BUILD_DIR} ; fi
	if [ -d ${SPDM_DIR}/build_host ] ; then rm -rf ${SPDM_DIR}/build_host ; fi

clean: ${CLEANERS}

