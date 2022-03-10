include(ExternalProject)

set_property (DIRECTORY PROPERTY EP_BASE Dependencies)

## ADI HDL Project.
set(EXT_PROJECT hdl)

set(EXT_PROJECT_GIT_BRANCH "master")
set(EXT_PROJECT_GIT_COMMIT "")

set(EXT_PROJECT_REPOSITORY "https://github.com/analogdevicesinc/hdl.git")

set(HDL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${EXT_PROJECT}/src/${EXT_PROJECT}/projects/adrv9364z7020/ccbob_lvds/adrv9364z7020_ccbob_lvds.runs/impl_1)

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
		${CMAKE_CURRENT_SOURCE_DIR}/patches/scripts/apply_patches.sh ${CMAKE_CURRENT_SOURCE_DIR}/patches/hdl
	BUILD_IN_SOURCE 1
	CONFIGURE_COMMAND ""
	BUILD_COMMAND make adrv9364z7020.ccbob_lvds
	BUILD_BYPRODUCTS ${HDL_DIR}/system_top.sysdef ${HDL_DIR}/system_top.bit
	INSTALL_COMMAND
		${CMAKE_COMMAND} -E copy_if_different ${HDL_DIR}/system_top.bit
			${CMAKE_CURRENT_BINARY_DIR}/image/boot/system.bit &&
		${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/boot_gen &&
		${CMAKE_COMMAND} -E copy_if_different ${HDL_DIR}/system_top.sysdef
			${CMAKE_CURRENT_BINARY_DIR}/boot_gen/system_top.sysdef
)

list (APPEND DEPENDENCIES ${EXT_PROJECT})
