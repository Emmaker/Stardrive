# Usage:
#   dub_package(
#       NAME mydep
#       PACKAGE_NAME vibe-d
#       VERSION 0.10.0
#       OUT_TARGET vibe_d_lib
#   )
#
# After this call:
#   - ${vibe_d_lib} will be a CMake target you can link against.
#   - The package is stored under: ${CMAKE_BINARY_DIR}/dub/mydep
#

find_program(DUB_BIN NAMES dub)
if(NOT DUB_BIN)
    message(FATAL_ERROR "dub was not found. Please install dub to use D packages.")
endif()

function(find_dub_package)
    cmake_parse_arguments(DP
        ""
        "NAME;PACKAGE_NAME;VERSION;OUT_TARGET"
        ""
        ${ARGN}
    )

    if(NOT DP_NAME)
        message(FATAL_ERROR "dub_package(): NAME is required")
    endif()

    if(NOT DP_PACKAGE_NAME)
        message(FATAL_ERROR "dub_package(): PACKAGE_NAME is required")
    endif()

    if(DP_VERSION)
        set(DP_PACKAGE_FULLNAME "${DP_PACKAGE_NAME}@${DP_VERSION}")
    else()
        set(DP_PACKAGE_FULLNAME "${DP_PACKAGE_NAME}")
    endif()

    execute_process(
        COMMAND ${DUB_BIN} fetch ${DP_PACKAGE_FULLNAME}
        RESULT_VARIABLE FETCH_RESULT
    )

    if(NOT FETCH_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to fetch DUB package ${DP_PACKAGE_NAME}")
    endif()

    execute_process(
        COMMAND ${DUB_BIN} build ${DP_PACKAGE_FULLNAME}
        RESULT_VARIABLE BUILD_RESULT
    )

    if(NOT BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to build DUB package ${DP_PACKAGE_NAME}")
    endif()

    # Obtain a description of the dub package
    execute_process(
        COMMAND ${DUB_BIN} describe ${DP_PACKAGE_NAME}
        OUTPUT_VARIABLE DUB_DESC
    )

    # Extract the package path
    string(JSON DUB_PATH GET "${DUB_DESC}" "packages" 0 "path")

    if(NOT DUB_PATH)
        message(FATAL_ERROR "Could not determine dub package fetch path")
    endif()

    # Extract the target path
    string(JSON DUB_TARGET_PATH GET "${DUB_DESC}" "packages" 0 "targetPath")
    set(DUB_TARGET_PATH "${DUB_PATH}/${DUB_TARGET_PATH}")

    # Extract the target object name
    string(JSON DUB_TARGET_NAME GET "${DUB_DESC}" "packages" 0 "targetFileName")

    set("${DP_NAME}_LIBRARY" "${DUB_TARGET_PATH}/${DUB_TARGET_NAME}" CACHE STRING
        "Where the object library of the package lives")

    string(JSON DUB_IMPORT_PATHS GET "${DUB_DESC}" "packages" 0 "importPaths")
    string(JSON L LENGTH "${DUB_IMPORT_PATHS}")
    math(EXPR L "${L}-1")

    set("${DP_NAME}_INCLUDE_DIR")
    foreach(i RANGE ${L})
        string(JSON P GET "${DUB_IMPORT_PATHS}" ${i})
        list(APPEND "${DP_NAME}_INCLUDE_DIR" "${DUB_PATH}/${P}")
    endforeach()

    set("${DP_NAME}_INCLUDE_DIR" ${${DP_NAME}_INCLUDE_DIR} CACHE STRING
        "Directories to include when building against the package")
endfunction()
