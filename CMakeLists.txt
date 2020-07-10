# CMake.
cmake_minimum_required(VERSION 3.17.0 FATAL_ERROR)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror -ggdb3")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror -ggdb3")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_COLOR_MAKEFILE ON)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
else()
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")
endif()

# Configure toolchain.
set(TGT_ARCH arm)
include(cmake/scripts/toolchain.cmake)

# Project configuration.
set(PROJECT_NAME adi_dmac_iio_dev)
project(${PROJECT_NAME} C)

include(CMakeDependentOption)

option(WITH_XILINX_PL_DMAC_EXAMPLE "Build FPGA image" ON)
option(WITH_XILINX_FSBL "Build First stage boot loader (FSBL)" ON)
option(WITH_XILINX_SSBL "Build Second stage boot loader (SSBL - UBOOT)" ON)

cmake_dependent_option(WITH_BOOT_BIN_GEN "Generate Zynq boot binary" ON
	"WITH_XILINX_PL_DMAC_EXAMPLE;WITH_XILINX_FSBL;WITH_XILINX_SSBL" OFF)

	option(WITH_ADI_LINUX_KERNEL "Build Linux kernel Image" ON)
option(WITH_DMAC_KMOD "Build kernel module" ON)
option(WITH_DMAC_EXAMPLE "Build examples" ON)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/image" CACHE PATH "default installation path" FORCE)
endif()

# CMake helpers.
include(GNUInstallDirs)

find_package (Git "2.14.0" REQUIRED)

if(WITH_XILINX_PL_DMAC_EXAMPLE)
	find_package(Vivado "2018.2" REQUIRED)

	include(cmake/scripts/hdl.cmake)

	set(WITH_SYSDEF_FILE ${CMAKE_CURRENT_BINARY_DIR}/boot_gen/system_top.sysdef)
endif()

if(WITH_XILINX_FSBL)
	set(HSI_VER 2018.2)
	find_package(HSI ${HSI_VER} REQUIRED)

	if(NOT WITH_SYSDEF_FILE)
		message(FATAL_ERROR "System Definition option not set via -DWITH_SYSDEF_FILE=<filename>")
	endif()

	include(cmake/scripts/fsbl.cmake)
endif()

if(WITH_XILINX_SSBL)
	include(cmake/scripts/ssbl.cmake)

	if(NOT SSBL_ETHADDR)
		set(SSBL_ETHADDR 00:e0:22:fe:ff:ff)
	endif()

	configure_file(uenv/uEnv.txt.in ${CMAKE_CURRENT_BINARY_DIR}/image/boot/uEnv.txt @ONLY)
endif()

if(WITH_BOOT_BIN_GEN)
	add_subdirectory(boot)
endif()

if(WITH_ADI_LINUX_KERNEL)
	set(UIMAGE_LOADADDR 0x8000)

	include(cmake/scripts/kernel.cmake)
endif()

if(WITH_DMAC_KMOD)
	if(NOT KERNEL_DIR)
		message(FATAL_ERROR "KERNEL_DIR must be set root of kernel sources when WITH_DMAC_KMOD is set")
	endif()

	include(cmake/scripts/dmac_kmod.cmake)
endif()

if(WITH_DMAC_EXAMPLE)
	add_subdirectory(test)
endif()
