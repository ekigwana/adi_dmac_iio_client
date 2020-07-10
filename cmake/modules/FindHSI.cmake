# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindHSI
# -------
#
# The module defines the following variables:
#
# ``HSI_EXECUTABLE``
#   Path to HSI software suite produced by Xilinx for synthesis and analysis of HDL designs.
# ``HSI_FOUND``, ``HSI_FOUND``
#   True if the HSI tool was found.
# ``HSI_VERSION_STRING``
#   The version of HSI found.
#
# Example usage:
#
# 	.. code-block:: cmake
#
# 	find_package(HSI)
#
# 	if(HSI_FOUND)
# 		message("HSI found: ${HSI_EXECUTABLE}")
# 	endif()

find_program(HSI_EXECUTABLE
	NAMES hsi
	ENV XILINX_HSI
	DOC "Software suite for synthesis and analysis of HDL designs")

mark_as_advanced(HSI_EXECUTABLE)

if(HSI_EXECUTABLE)
	execute_process(COMMAND ${HSI_EXECUTABLE} -version
		OUTPUT_VARIABLE hsi_version
		ERROR_QUIET
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	separate_arguments(hsi_version)
	list(GET hsi_version 1 hsi_version)
	string(REGEX REPLACE "[a-zA-v]+" "" HSI_VERSION_STRING ${hsi_version})
	unset(hsi_version)

	include(FindPackageHandleStandardArgs)

	find_package_handle_standard_args(HSI
		REQUIRED_VARS HSI_EXECUTABLE
		VERSION_VAR HSI_VERSION_STRING)
endif()
