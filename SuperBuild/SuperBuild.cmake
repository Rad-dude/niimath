# Check if git exists
find_package(Git)
if(NOT GIT_FOUND)
    message(FATAL_ERROR "Cannot find Git. Git is required for Superbuild")
endif()

# Use git protocol or not
option(USE_GIT_PROTOCOL "If behind a firewall turn this off to use http instead." ON)
if(USE_GIT_PROTOCOL)
    set(git_protocol "git")
else()
    set(git_protocol "https")
endif()

# Basic CMake build settings
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING
        "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS  "Debug;Release;RelWithDebInfo;MinSizeRel")
endif()
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

option(USE_STATIC_RUNTIME "Use static runtime" ON)

if(USE_STATIC_RUNTIME)
    if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
        find_file(STATIC_LIBCXX "libstdc++.a" ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES})
        mark_as_advanced(STATIC_LIBCXX)
        if(NOT STATIC_LIBCXX)
            unset(STATIC_LIBCXX CACHE)
            # Only on some Centos/Redhat systems
            message(FATAL_ERROR
                "\"USE_STATIC_RUNTIME\" set to ON but \"libstdcxx.a\" not found! \
                 \"yum install libstdc++-static\" to resolve the error.")
        endif()
    endif()
endif()

include(ExternalProject)

set(DEPENDENCIES)

set(DEP_INSTALL_DIR ${CMAKE_BINARY_DIR})

set(ZLIB_IMPLEMENTATION "Cloudflare" CACHE STRING "Choose zlib implementation.")
set_property(CACHE ZLIB_IMPLEMENTATION PROPERTY STRINGS  "Cloudflare;System;Custom")
if(${ZLIB_IMPLEMENTATION} STREQUAL "Cloudflare")
    message("-- Build with Cloudflare zlib: ON")
    include(${CMAKE_SOURCE_DIR}/SuperBuild/External-CLOUDFLARE-ZLIB.cmake)
    list(APPEND DEPENDENCIES zlib)
    set(BUILD_CLOUDFLARE-ZLIB TRUE)
    message("--   Will build Cloudflare zlib from github")
elseif(${ZLIB_IMPLEMENTATION} STREQUAL "Custom")
    set(ZLIB_ROOT ${ZLIB_ROOT} CACHE PATH "Specify custom zlib root directory.")
    if(NOT ZLIB_ROOT)
        message(FATAL_ERROR "ZLIB_ROOT needs to be set to locate custom zlib!")
    endif()
endif()

ExternalProject_Add(src
    DEPENDS ${DEPENDENCIES}
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/src
    BINARY_DIR src-build
    CMAKE_ARGS
        -Wno-dev
        --no-warn-unused-cli
        -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
        -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}
        -DCMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS}
        -DCMAKE_CXX_FLAGS:STRING=${CMAKE_CXX_FLAGS}
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=${CMAKE_VERBOSE_MAKEFILE}
        -DUSE_STATIC_RUNTIME:BOOL=${USE_STATIC_RUNTIME}
        -DZLIB_IMPLEMENTATION:STRING=${ZLIB_IMPLEMENTATION}
        -DZLIB_ROOT:PATH=${ZLIB_ROOT}
)

install(DIRECTORY ${CMAKE_BINARY_DIR}/bin/ DESTINATION bin
        USE_SOURCE_PERMISSIONS)

option(BUILD_DOCS "Build documentation (manpages)" OFF)
if(BUILD_DOCS)
    add_subdirectory(docs)
endif()

