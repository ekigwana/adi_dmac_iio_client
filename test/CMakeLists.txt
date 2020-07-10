set(SUBPROJECT_NAME adi_dmac_iio_test)
set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake)

if(CMAKE_SYSROOT)
	set(ENV{PKG_CONFIG_DIR} "")
	set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_SYSROOT}/usr/${CMAKE_INSTALL_LIBDIR}/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig")
	set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})
endif()

find_package(PkgConfig REQUIRED)
pkg_search_module(libiio REQUIRED IMPORTED_TARGET libiio>=0.18)

set(SUBPROJECT_SOURCES iio_axi_dmac_test.c)

add_executable(${SUBPROJECT_NAME} ${SUBPROJECT_SOURCES})

target_link_libraries(${SUBPROJECT_NAME} PkgConfig::libiio)

# Install.
install(TARGETS ${SUBPROJECT_NAME} RUNTIME DESTINATION root/bin)
