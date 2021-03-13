CMAKE_MINIMUM_REQUIRED(VERSION 3.13)

PROJECT(cpp-multi-platform-mgr)

set(COMMON_FLAG " -w -mconsole -U__STRICT_ANSI__ -fpermissive -static -ffunction-sections -fdata-sections -fvisibility=hidden " CACHE INTERNAL "COMMON_FLAG")

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)
if (COMPILER_SUPPORTS_GC_SECTIONS)
    set(COMMON_FLAG "-Wl,--gc-sections ${COMMON_FLAG}")
endif ()

CHECK_CXX_COMPILER_FLAG("-static-libstdc++ -static-libgcc" COMPILER_SUPPORTS_STATIC_CXX)
if (COMPILER_SUPPORTS_STATIC_CXX)
    set(COMMON_FLAG "${COMMON_FLAG} -static-libstdc++ -static-libgcc")
endif ()

CHECK_CXX_COMPILER_FLAG("-mfma" COMPILER_SUPPORTS_MFMA)
if (COMPILER_SUPPORTS_MFMA)
    set(COMMON_FLAG "-mfma ${COMMON_FLAG}")
endif ()

CHECK_CXX_COMPILER_FLAG("-msse4.1" COMPILER_SUPPORTS_MSSE41)
if (COMPILER_SUPPORTS_MSSE41)
    set(COMMON_FLAG "-msse4.1 ${COMMON_FLAG}")
endif ()

CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
if (COMPILER_SUPPORTS_CXX14)
    set(COMMON_FLAG "${COMMON_FLAG} -std=c++14")
elseif (COMPILER_SUPPORTS_CXX11)
    set(COMMON_FLAG "${COMMON_FLAG} -std=c++11")
else ()
    message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif ()

include(CheckLinkerFlag)
check_linker_flag(CXX "-Wl,--unresolved-symbols=ignore-in-shared-libs" CHECK_UNRESOLVED_SYMBOLS)
if (CHECK_UNRESOLVED_SYMBOLS)
    add_link_options(-Wl,--unresolved-symbols=ignore-in-shared-libs)
endif (CHECK_UNRESOLVED_SYMBOLS)

check_linker_flag(CXX "-Wl,--enable-stdcall-fixup,--add-stdcall-alias" CHECK_ENABLE_STDCALL_FIXUP)
if (CHECK_ENABLE_STDCALL_FIXUP)
    add_link_options(-Wl,--enable-stdcall-fixup,--add-stdcall-alias)
endif (CHECK_ENABLE_STDCALL_FIXUP)

check_linker_flag(CXX "-Wl,--output-def,aicae_${CMAKE_BUILD_TYPE}.def" CHECK_OUTPUT_DEF)
if (CHECK_OUTPUT_DEF)
    add_link_options(-Wl,--output-def,aicae_${CMAKE_BUILD_TYPE}.def)
endif (CHECK_OUTPUT_DEF)

ADD_SUBDIRECTORY(../../projects projects)
