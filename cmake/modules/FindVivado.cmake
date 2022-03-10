# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindVivado
# -------
#
# The module defines the following variables:
#
# ``VIVADO_EXECUTABLE``
#   Path to Vivado software suite produced by Xilinx for synthesis and analysis of HDL designs.
# ``Vivado_FOUND``, ``VIVADO_FOUND``
#   True if the Vivado tool was found.
# ``VIVADO_VERSION_STRING``
#   The version of Vivado found.
#
# Example usage:
#
# 	.. code-block:: cmake
#
# 	find_package(Vivado)

find_program(VIVADO_EXECUTABLE
	NAMES vivado
	ENV XILINX_VIVADO
	DOC "Software suite for synthesis and analysis of HDL designs")

if(NOT VIVADO_EXECUTABLE)
	message(FATAL_ERROR "vivado command not found! Run: \nsource /opt/Xilinx/Vivado/${Vivado_FIND_VERSION}/settings64.sh\n")
endif()

mark_as_advanced(VIVADO_EXECUTABLE)

if(VIVADO_EXECUTABLE)
	execute_process(COMMAND ${VIVADO_EXECUTABLE} -version
		OUTPUT_VARIABLE vivado_version
		ERROR_QUIET
		OUTPUT_STRIP_TRAILING_WHITESPACE)

	separate_arguments(vivado_version)
	list(GET vivado_version 1 vivado_version)
	string(REGEX REPLACE "[a-zA-v]+" "" VIVADO_VERSION_STRING ${vivado_version})
	unset(vivado_version)
endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(Vivado
	REQUIRED_VARS VIVADO_EXECUTABLE
	VERSION_VAR VIVADO_VERSION_STRING
)
