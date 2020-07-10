#
# Makefile iio_axi_dmac
#
CROSS_CC     = armv7a-hardfloat-linux-gnueabi-
TARGET_ARCH  = arm
TARGET_ROOT  = /home/system/zynq/os/gentoo
KERNELDIR    = ../../linux

MODULES      = iio_axi_dmac.ko
TEST_CC      = $(CROSS_CC)gcc
TEST_CFLAGS  = -Wall -Werror

# Extra libs are if libiio has the kitchen sink built in
EXTRA_LIBS   = -lavahi-common -lavahi-client -lxml2
TEST_LIBS    = -liio $(EXTRA_LIBS)
TEST_LDFLAGS = -L.

obj-m += iio_axi_dmac.o

all: modules iio_axi_dmac_test

modules:
	make ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(CROSS_CC) -C $(KERNELDIR) \
			M=$(PWD) modules

iio_axi_dmac_test: iio_axi_dmac_test.c
	$(TEST_CC) $(TEST_CFLAGS) -o $@ $< I. $(TEST_LDFLAGS) $(TEST_LIBS)

clean:
	rm -f iio_axi_dmac_test
	make -C $(KERNELDIR) M=$(PWD) clean

install:
	make ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(CROSS_CC) \
			INSTALL_MOD_PATH=$(TARGET_ROOT) -C $(KERNELDIR) \
			M=$(PWD) modules_install
