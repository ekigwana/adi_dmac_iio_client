find_package(Bootgen "2018.2" REQUIRED)

if(NOT ${Bootgen_FOUND})
	message(STATUS "Unable to find Bootgen executable. Not preparing boot binary.")
	return()
endif()

# Generate boot binary.
set(BOOTGEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/boot_gen)
configure_file(boot.bif.in ${BOOTGEN_DIR}/boot.bif)

add_custom_target(boot.bin ALL
	DEPENDS ${FSBL_DIR}/executable.elf ${SSBL_DIR}/u-boot ${BOOTGEN_DIR}/boot.bif
	COMMAND ${BOOTGEN_EXECUTABLE} -w -image boot.bif -o i ${CMAKE_CURRENT_BINARY_DIR}/image/boot/boot.bin
	COMMENT "Generating boot binary..."
	WORKING_DIRECTORY ${BOOTGEN_DIR}
	USES_TERMINAL
)
