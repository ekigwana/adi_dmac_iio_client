include(ExternalProject)

set_property (DIRECTORY PROPERTY EP_BASE Dependencies)

## Linux kernel.
set(EXT_PROJECT kernel)

set(EXT_PROJECT_GIT_BRANCH "master")
set(EXT_PROJECT_GIT_COMMIT "")

if(USE_HTTPS_REPO_URI)
	set(EXT_PROJECT_REPOSITORY "https://repo.scires.com/scm/mir/adi_linux.git")
	# set(EXT_PROJECT_REPOSITORY "https://github.com/analogdevicesinc/linux.git")
else()
	set(EXT_PROJECT_REPOSITORY "ssh://git@repo.scires.com:7999/mir/adi_linux.git")
endif()

set(KERNEL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${EXT_PROJECT}/src/${EXT_PROJECT})

# Set build flags based on processor count.
include(ProcessorCount)

ProcessorCount(N)

if(NOT N EQUAL 0)
  set(BUILD_FLAGS -j${N})
endif()

ExternalProject_Add(${EXT_PROJECT}
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
		${CMAKE_CURRENT_SOURCE_DIR}/patches/scripts/apply_patches.sh ${CMAKE_CURRENT_SOURCE_DIR}/patches/kernel
	BUILD_IN_SOURCE 1
	CONFIGURE_COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_CURRENT_BINARY_DIR}/dts &&
		${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_SOURCE_DIR}/dts ${CMAKE_CURRENT_BINARY_DIR}/dts &&
		${CMAKE_COMMAND} -E remove -f ${CMAKE_CURRENT_BINARY_DIR}/image &&
		make ARCH=${TGT_ARCH} CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} zynq_adrv9361_dij_defconfig
	BUILD_COMMAND make ARCH=${TGT_ARCH} CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} ${BUILD_FLAGS}
		UIMAGE_LOADADDR=${UIMAGE_LOADADDR} uImage && make ARCH=${TGT_ARCH}
		CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} ${BUILD_FLAGS} modules && make ARCH=${TGT_ARCH}
		CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} ${BUILD_FLAGS} dtbs
	BUILD_BYPRODUCTS ${KERNEL_DIR}/arch/arm/boot/uImage ${CMAKE_CURRENT_BINARY_DIR}/image/lib
	INSTALL_COMMAND make ARCH=${TGT_ARCH} CROSS_COMPILE=${CMAKE_TOOLCHAIN_PREFIX} ${BUILD_FLAGS}
		modules_install INSTALL_MOD_PATH=${CMAKE_CURRENT_BINARY_DIR}/image &&
		${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/image/boot &&
		${CMAKE_COMMAND} -E copy_if_different ${KERNEL_DIR}/arch/arm/boot/uImage
			${CMAKE_CURRENT_BINARY_DIR}/image/boot/uImage &&
		${CMAKE_COMMAND} -E copy_if_different ${KERNEL_DIR}/arch/arm/boot/dts/zynq-adrv9364z7020.dtb
			${CMAKE_CURRENT_BINARY_DIR}/image/boot/system.dtb
)

list (APPEND DEPENDENCIES ${EXT_PROJECT})
