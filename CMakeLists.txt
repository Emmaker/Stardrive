cmake_minimum_required(VERSION 3.31)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

project(Stardrive LANGUAGES D C)

include(DubPackage)
find_dub_package(
    NAME SDLD
    PACKAGE_NAME sdl-d
)

include_directories(source)
set(STAR_COMMON_SRC
    source/posix/fd.d

    source/star/assets.d
    source/star/sbasset.d
    source/star/sbon.d
    source/star/stream.d
)

if(UNIX)
    set(STAR_PLATFORM_SRC
        source/posix/unix_fd.c
    )
else()
    message(FATAL_ERROR "Unrecognized platform")
endif()

add_executable(assetpak
    ${STAR_COMMON_SRC}
    ${STAR_PLATFORM_SRC}

    source/assetpak.d
)