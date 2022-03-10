# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindBootgen
# -------
#
# The module defines the following variables:
#
# ``BOOTGEN_EXECUTABLE``
#   Path to Bootgen software suite produced by Xilinx for synthesis and analysis of HDL designs.
# ``Bootgen_FOUND``, ``BOOTGEN_FOUND``
#   True if the Bootgen tool was found.
# ``BOOTGEN_VERSION_STRING``
#   The version of Bootgen found.
#
# Example usage:
#
# 	.. code-block:: cmake
#
# 	find_package(Bootgen)
#
# 	if(Bootgen_FOUND)
# 		message("Bootgen found: ${BOOTGEN_EXECUTABLE}")
# 	endif()

find_program(BOOTGEN_EXECUTABLE
	NAMES bootgen
	ENV XILINX_BOOTGEN
	DOC "Part of Vivado software suite for synthesis and analysis of HDL designs")

mark_as_advanced(BOOTGEN_EXECUTABLE)

if(BOOTGEN_EXECUTABLE)
	execute_process(COMMAND ${BOOTGEN_EXECUTABLE} -help
		OUTPUT_VARIABLE bootgen_version
		ERROR_QUIET
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	separate_arguments(bootgen_version)
	list(GET bootgen_version 3 bootgen_version)
	string(REGEX REPLACE "[a-zA-v]+" "" BOOTGEN_VERSION_STRING ${bootgen_version})
	unset(bootgen_version)

	include(FindPackageHandleStandardArgs)

	find_package_handle_standard_args(Bootgen
		REQUIRED_VARS BOOTGEN_EXECUTABLE
		VERSION_VAR BOOTGEN_VERSION_STRING)
endif()
