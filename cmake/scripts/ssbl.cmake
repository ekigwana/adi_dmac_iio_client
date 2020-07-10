include(ExternalProject)

set_property (DIRECTORY PROPERTY EP_BASE Dependencies)

## Universal Boot Loader.
set(EXT_PROJECT ssbl)

set(EXT_PROJECT_GIT_BRANCH "master")
set(EXT_PROJECT_GIT_COMMIT "xilinx-v2018.2")

if(USE_HTTPS_REPO_URI)
	set(EXT_PROJECT_REPOSITORY "https://repo.scires.com/scm/mir/u-boot-xlnx.git")
	# set(EXT_PROJECT_REPOSITORY "https://github.com/Xilinx/u-boot-xlnx.git")
else()
	set(EXT_PROJECT_REPOSITORY "ssh://git@repo.scires.com:7999/mir/u-boot-xlnx.git")
endif()

set(SSBL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${EXT_PROJECT}/src/${EXT_PROJECT})

# Set build flags based on processor count.
include(ProcessorCount)

ProcessorCount(N)

if(NOT N EQUAL 0)
  set(BUILD_FLAGS -j${N})
endif()

ExternalProject_Add(${EXT_PROJECT}
	DEPENDS fsbl
	PREFIX ${EXT_PROJECT}
	GIT_REPOSITORY ${EXT_PROJECT_REPOSITORY}
	GIT_TAG ${EXT_PROJECT_GIT_BRANCH}
	GIT_SHALLOW 1
	USES_TERMINAL_DOWNLOAD 1
	USES_TERMINAL_UPDATE 1
	USES_TERMINAL_CONFIGURE 1
	USES_TERMINAL_BUILD 1
	USES_TERMINAL_INSTALL 1
	USES_TERMINAL_TEST 1
	UPDATE_COMMAND git checkout ${EXT_PROJECT_GIT_COMMIT} && git checkout -B ${EXT_PROJECT} &&
		${CMAKE_CURRENT_SOURCE_DIR}/patches/scripts/apply_patches.sh ${CMAKE_CURRENT_SOURCE_DIR}/patches/ssbl
	BUILD_IN_SOURCE 1
	CONFIGURE_COMMAND make ARCH=${TGT_ARCH} CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} zynq_adrv9361_m6_defconfig
	BUILD_COMMAND make ARCH=${TGT_ARCH} CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} ${BUILD_FLAGS}
	BUILD_BYPRODUCTS ${SSBL_DIR}/u-boot
	INSTALL_COMMAND
		${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/boot_gen &&
		${CMAKE_COMMAND} -E copy_if_different ${SSBL_DIR}/u-boot ${CMAKE_CURRENT_BINARY_DIR}/boot_gen/u-boot.elf
)

list (APPEND DEPENDENCIES ${EXT_PROJECT})
