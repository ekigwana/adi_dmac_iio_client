include(ExternalProject)

set_property (DIRECTORY PROPERTY EP_BASE Dependencies)

## Use HSI and system definition to generate fsbl project files.
set(EXT_PROJECT fsbl)
set(HSI_GEN_FSBL_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/scripts/hsi_gen_fsbl.tcl)
set(FSBL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${EXT_PROJECT}/src/${EXT_PROJECT})

ExternalProject_Add(${EXT_PROJECT}
	DEPENDS hdl
	PREFIX ${EXT_PROJECT}
	USES_TERMINAL_DOWNLOAD 1
	USES_TERMINAL_UPDATE 1
	USES_TERMINAL_CONFIGURE 1
	USES_TERMINAL_BUILD 1
	USES_TERMINAL_INSTALL 1
	USES_TERMINAL_TEST 1
	DOWNLOAD_COMMAND ""
	BUILD_IN_SOURCE 1
	CONFIGURE_COMMAND ""
	BUILD_COMMAND SYSDEF_FILE=${WITH_SYSDEF_FILE} BASE_DIR=${FSBL_DIR} PROJECT_NAME=${EXT_PROJECT}
		REQUIRED_HSI_VERSION=${HSI_VER} hsi -nojournal -nolog -mode tcl -source ${HSI_GEN_FSBL_SCRIPT}
	BUILD_BYPRODUCTS ${FSBL_DIR}/executable.elf
	INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/boot_gen &&
		${CMAKE_COMMAND} -E copy_if_different ${FSBL_DIR}/executable.elf
			${CMAKE_CURRENT_BINARY_DIR}/boot_gen/fsbl.elf
)

list (APPEND DEPENDENCIES ${EXT_PROJECT})