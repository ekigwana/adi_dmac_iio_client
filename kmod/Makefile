# Get these variables from the environment if set
ARCH ?= arm
CROSS_COMPILE ?= armv7a-unknown-linux-gnueabihf-
INSTALL_MOD_PATH ?=
INSTALL_MOD_DIR ?= extra/drivers/iio/misc
KBUILD ?= /lib/modules/$(shell uname -r)/build/

obj-m := iio_axi_dmac.o

default:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KBUILD) \
		M=$(PWD) modules

clean:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KBUILD) \
		M=$(PWD) clean

modules_install:
	$(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) \
		INSTALL_MOD_DIR=$(INSTALL_MOD_DIR) \
		INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) -C $(KBUILD) \
		M=$$PWD modules_install
