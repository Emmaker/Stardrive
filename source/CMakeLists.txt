cmake_minimum_required(VERSION 3.31)

list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/../cmake"
)

project(Stardrive LANGUAGES D C)

include(DubPackage)
find_dub_package(
    NAME SDLD
    PACKAGE_NAME sdl-d
)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)
set(STAR_COMMON_SRC
    star/stream/file.d
    star/stream/istream.d
    star/stream/package.d

    star/assets.d
    star/sbasset.d
    star/sbon.d
)

add_executable(assetpak
    ${STAR_COMMON_SRC}

    assetpak.d
)
