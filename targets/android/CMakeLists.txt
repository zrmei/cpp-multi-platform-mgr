CMAKE_MINIMUM_REQUIRED(VERSION 3.13)

if(NOT "${ANDROID_TOOLCHAIN}" STREQUAL "gcc")
    unset(ANDROID_NATIVE_API_LEVEL)
    set(ANDROID_NATIVE_API_LEVEL 19 CACHE STRING "" FORCE)

    unset(ANDROID_TOOLCHAIN)
    set(ANDROID_TOOLCHAIN gcc CACHE STRING "" FORCE)

    unset(ANDROID_STL)
    set(ANDROID_STL gnustl_static CACHE STRING "" FORCE)
endif()

PROJECT(cpp-multi-platform-mgr)

SET(CMAKE_SYSTEM_NAME Android)

if(NOT DEFINED PLATFORM)
    SET(PLATFORM ${ANDROID_ABI})
endif()

OPTION(GENERATE_LIB_OR_BIN "生成动态库或可执行文件，ON为LIB" ON)

set(NDK_SUPPORTED OFF)
if (EXISTS "${ANDROID_NDK}/source.properties")
    file(STRINGS "${ANDROID_NDK}/source.properties" NDK_PROPERTIES)

    if (NDK_PROPERTIES MATCHES "Pkg\\.Revision.*=.*16\\.")
        set(NDK_SUPPORTED ON)
    endif ()
endif ()

if (NOT NDK_SUPPORTED)
    MESSAGE(FATAL_ERROR "only support Android ndk r16b")
endif ()

ADD_SUBDIRECTORY(../../projects projects)


