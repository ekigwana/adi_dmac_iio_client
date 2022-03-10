# ADI AXI DMAC Development System on ADRV9364z7020 Platform
## Description
This project contains all the components sans an OS image required to develop and test a projects requiring a streaming
DMA interface.

This project builds and generates all components that can be copied to an existing OS image to facilitate development.
This project consists of the following components:

* **Firmware** - FPGA hardware bitstream image for a ADRV9364z7020 transceiver to configure the Zynq SoC for
required functionality.

* **FSBL** - First Stage Bootloader for a Zynq 7000 SoC that loads the 2nd Stage Boot Loader image from the non-volatile
memory (SD) to Memory (DDR/TCM/OCM) and takes Arm processor out of reset.

* **SSBL** - Configures the FPGA with the appropriate hardware bitstream. The SSBL loads the Operating System (OS)
kernel Image and executes it.

* **Boot Bin Generation** - Generates the boot binary a Zynq 7000 SoC. The SoC is expected to load it from SD
non-volatile storage

* **Kernel and Device Tree Blob (dtb)** - The Linux kernel is part of the OS. The DTB describes all available system
hardware to include that instantiated in the FPGA. The kernel uses this information to load the appropriate system level
drivers facilitating access to hardware.

* **Operating System** - Not provided but required to test. Some ready made OS images and instructions on getting an OS
on bootable media are here: [AD-FMC-SDCARD for Zynq & Altera SoC Quick Start Guide](https://wiki.analog.com/resources/tools-software/linux-software/zynq_images)

* **Kernel Module** - Custom IIO driver that uses the Linux IIO AXI DMAC driver to bring streaming interfaces to
userspace via [IIO](https://wiki.analog.com/software/linux/docs/iio/iio).

* **Example Streaming Application** - Example demonstrating how to use the
[IIO library](https://wiki.analog.com/resources/tools-software/linux-software/libiio) to stream data.

## Requirements
The following software is required to build the bitstream:

1. GNU environment providing GCC compiler
2. CMake
3. ninja or make
4. xilinx vivado version 2018.2
5. OS image files in a directory. Can be the boot media but it is recommended to copy the root filesystem to a location
such as: /opt/armv7a/adi_zynq_img/

## Building
Building all components is enabled by default. When focusing on a particular component, all other may be disabled as
long as they are not dependent components. A tool chain prefix and OS system root are required to build all components.
The tool chain prefix for tools that are part of Vivado 2018.2 is arm-linux-gnueabihf-. When building the SSBL, the
Ethernet MAC address may be specified on the command line as follows: -DSSBL_ETHADDR="00:e0:22:fe:ff:ff"

1. mkdir build
2. cd build
3. cmake -G Ninja -DCMAKE_TOOLCHAIN_PREFIX=armv7a-unknown-linux-gnueabihf- -DCMAKE_SYSROOT=/opt/armv7a/adi_zynq_img/ ..
4. ninja -v

## Install
1. ninja -v install

## Output Products
The all components located in the build/image or install prefix subdirectory. The products in this directory are then
transfered to the boot media using common file tranfer methods.
