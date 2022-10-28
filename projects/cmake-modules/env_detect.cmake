include(CheckCXXCompilerFlag)
include(CheckSymbolExists)
include(CheckFunctionExists)
include(CheckCXXSourceCompiles)

macro(CHECK_PTHREAD_SETNAME)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)
    list(APPEND CMAKE_REQUIRED_LIBRARIES pthread)
    check_symbol_exists(pthread_setname_np "pthread.h" HAVE_pthread_setname_np)
    list(REMOVE_ITEM CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)
    if (NOT HAVE_pthread_setname_np)
        add_compile_definitions(PTHREAD_SETNAME_NOT_SUPPORTED)
    endif ()
endmacro()

function(CheckForLinuxPlatform)
    SET(COMMON_FLAG " -w -fPIC -pipe -Wl,-z,muldefs -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden -Bsymbolic")

    CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)
    if (COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG "-Wl,--gc-sections ${COMMON_FLAG}")
    endif ()

    set(CMAKE_REQUIRED_FLAGS "-static-libstdc++ -static-libgcc")
    file(READ ${CMAKE_CURRENT_LIST_DIR}/cmake-modules/test-static.txt _test_static)
    check_cxx_source_compiles("${_test_static}" COMPILER_SUPPORTS_STATIC_STDCXX)
    if (COMPILER_SUPPORTS_STATIC_STDCXX)
        set(COMMON_FLAG "${COMMON_FLAG} -static-libstdc++ -static-libgcc")
    endif ()
    unset(CMAKE_REQUIRED_FLAGS)
    unset(_test_static)

    if (PLATFORM MATCHES "x86|x64")
        CHECK_CXX_COMPILER_FLAG("-msse -mfpmath=sse" COMPILER_SUPPORTS_MSSE)
        if (COMPILER_SUPPORTS_MSSE)
            set(COMMON_FLAG "-msse -mfpmath=sse -DUSE_SSE -D_USE_SSE ${COMMON_FLAG}")
        endif ()
    elseif (PLATFORM MATCHES "aarch64")
        set(COMMON_FLAG "${COMMON_FLAG} -DUSE_NEON -DFLOAT_APPROX")
    else ()
        file(READ ${CMAKE_CURRENT_LIST_DIR}/cmake-modules/test-neon.txt _test_neon)

        set(CMAKE_REQUIRED_FLAGS "-mfpu=neon -mfloat-abi=softfp -DUSE_NEON -DFLOAT_APPROX")
        check_cxx_source_compiles("${_test_neon}" COMPILER_SUPPORTS_ARM_NEON_SOFTFP)
        if (COMPILER_SUPPORTS_ARM_NEON_SOFTFP)
            set(COMMON_FLAG "${COMMON_FLAG} ${CMAKE_REQUIRED_FLAGS}")
        endif ()
        unset(CMAKE_REQUIRED_FLAGS)

        set(CMAKE_REQUIRED_FLAGS "-mfpu=neon -mfloat-abi=hard -DUSE_NEON -DFLOAT_APPROX")
        check_cxx_source_compiles("${_test_neon}" COMPILER_SUPPORTS_ARM_NEON_HARD)
        if (COMPILER_SUPPORTS_ARM_NEON_HARD)
            set(COMMON_FLAG "${COMMON_FLAG} ${CMAKE_REQUIRED_FLAGS}")
        endif ()
        unset(CMAKE_REQUIRED_FLAGS)
        unset(_test_neon)
    endif ()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    if (COMPILER_SUPPORTS_CXX11)
        set(COMMON_FLAG "${COMMON_FLAG} -std=c++11")
    else ()
        message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif ()

    MESSAGE(STATUS "SIZE LENGTH " ${CMAKE_SIZEOF_VOID_P})

    IF (CMAKE_SIZEOF_VOID_P EQUAL 8)
        MESSAGE(STATUS "current platform: Linux  64")

        IF (PLATFORM MATCHES "x86")
            MESSAGE(STATUS "build 32 bit lib in 64 os system")

            SET(COMMON_FLAG "${COMMON_FLAG} -m32")
        ENDIF ()

        IF (COMPILER MATCHES "THIRDPLATFORM")
            SET(LINK_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/../libs/thirdplatform PARENT_SCOPE)
            SET(AIUI_LIBRARY_TYPE thirdplatform)

            MESSAGE(STATUS "complile for thirdplatform library.")
        ELSE ()
            SET(LINK_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/../libs/linux/${PLATFORM} PARENT_SCOPE)
            SET(AIUI_LIBRARY_TYPE ${PLATFORM} PARENT_SCOPE)
        ENDIF ()

    ELSE ()
        IF (PLATFORM MATCHES "x64")
            MESSAGE(FATAL_ERROR "can not build 64bit on 32 os system")
        ENDIF ()

        SET(LINK_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/../libs/linux/${PLATFORM} PARENT_SCOPE)
        SET(AIUI_LIBRARY_TYPE ${PLATFORM} PARENT_SCOPE)
    ENDIF ()

    CHECK_PTHREAD_SETNAME()

    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--exclude-libs,ALL")
    #set(COMMON_FLAG "${COMMON_FLAG} -Wl,--unresolved-symbols=ignore-in-shared-libs")
    #set(COMMON_FLAG "${COMMON_FLAG} -Wl,--warn-unresolved-symbols")

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)

    check_function_exists(gettid HAVE_GETTID)
    if (HAVE_GETTID)
        add_definitions(-DHAVE_GETTID)
    endif (HAVE_GETTID)

endfunction()


macro(source_group_by_dir abs_cur_dir source_files)
    if (MSVC)
        set(sgbd_cur_dir ${${abs_cur_dir}})
        foreach (sgbd_file ${${source_files}})
            string(REGEX REPLACE ${sgbd_cur_dir}/\(.*\) \\1 sgbd_fpath ${sgbd_file})
            string(REGEX REPLACE "\(.*\)/.*" \\1 sgbd_group_name ${sgbd_fpath})
            string(COMPARE EQUAL ${sgbd_fpath} ${sgbd_group_name} sgbd_nogroup)
            string(REPLACE "/" "\\" sgbd_group_name ${sgbd_group_name})
            if (sgbd_nogroup)
                set(sgbd_group_name "\\")
            endif (sgbd_nogroup)
            source_group(${sgbd_group_name} FILES ${sgbd_file})
        endforeach (sgbd_file)
    endif (MSVC)
endmacro(source_group_by_dir)

function(CheckForWindowsPlatform)
    IF (MSVC)
        SET(COMMON_FLAG "/W0 /nologo /utf-8 /Gm- /errorReport:prompt /WX- /Zc:wchar_t /Zc:inline /Zc:forScope /GR /Gd /Oy- /MT /EHsc /MP")

        if (CMAKE_BUILD_TYPE MATCHES "Debug")
            SET(COMMON_FLAG " ${COMMON_FLAG} /GS")
        endif ()

        if (NOT AIUI_DEBUG)
            set(COMMON_FLAG "${COMMON_FLAG} /Os")
        endif (NOT AIUI_DEBUG)

        CHECK_CXX_COMPILER_FLAG("/std:c++11" COMPILER_SUPPORTS_CXX11)
        if (COMPILER_SUPPORTS_CXX11)
            set(COMMON_FLAG "${COMMON_FLAG} /std:c++11")
        endif (COMPILER_SUPPORTS_CXX11)

        if (PLATFORM MATCHES "(x86|x64)")
            set(COMMON_FLAG "${COMMON_FLAG} /DUSE_SSE /D_USE_SSE")
        endif ()

        # It is very important for windows linker to ignore the redefined sysmbols between poco and msvc
        #/FORCE:MULTIPLE
        SET(CMAKE_STATIC_LINKER_FLAGS "/FORCE:MULTIPLE /NODEFAULTLIB:library" PARENT_SCOPE)
        SET(CMAKE_SHARED_LINKER_FLAGS "/FORCE:MULTIPLE /NODEFAULTLIB:library" PARENT_SCOPE)
        SET(WIN_TOOLSET_VERSION ${MSVC_TOOLSET_VERSION} PARENT_SCOPE)
    ELSE (MSVC)
        SET(WIN_TOOLSET_VERSION ${CMAKE_CXX_COMPILER_VERSION} PARENT_SCOPE)
        CHECK_PTHREAD_SETNAME()

        if (PLATFORM MATCHES "(x86|x64)")
            set(COMMON_FLAG "${COMMON_FLAG} -DUSE_SSE -D_USE_SSE")
        endif ()
    ENDIF (MSVC)

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
endfunction()


function(CheckForAndroidPlatform)
    SET(COMMON_FLAG " -w -fPIC -ffunction-sections -fdata-sections -fvisibility=hidden")

    CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)
    if (COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG "-Wl,--gc-sections ${COMMON_FLAG}")
    endif ()

    CHECK_CXX_COMPILER_FLAG("-mfma" COMPILER_SUPPORTS_MFMA)
    if (COMPILER_SUPPORTS_MFMA)
        set(COMMON_FLAG "-mfma ${COMMON_FLAG}")
    endif ()

    CHECK_CXX_COMPILER_FLAG("-msse4.1" COMPILER_SUPPORTS_MSSE41)
    if (COMPILER_SUPPORTS_MSSE41)
        set(COMMON_FLAG "-msse4.1 -DUSE_SSE -D_USE_SSE ${COMMON_FLAG}")
    endif ()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    if (COMPILER_SUPPORTS_CXX11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    else ()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif ()

    set(TEXT_COMMAND_FLAG "-mfpu=neon -ftree-vectorize -mfloat-abi=softfp")
    CHECK_CXX_COMPILER_FLAG("${TEXT_COMMAND_FLAG}" COMPILER_SUPPORTS_ARM_NEON)
    if (COMPILER_SUPPORTS_ARM_NEON)
        set(COMMON_FLAG "${COMMON_FLAG} ${TEXT_COMMAND_FLAG}")
    endif ()

    if ((COMPILER_SUPPORTS_ARM_NEON) OR (PLATFORM STREQUAL "arm64-v8a"))
        set(COMMON_FLAG "${COMMON_FLAG} -DUSE_NEON -DFLOAT_APPROX")
    endif ()

    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--exclude-libs,ALL")
    #set(COMMON_FLAG "${COMMON_FLAG} -Wl,--unresolved-symbols=ignore-in-shared-libs")
    #set(COMMON_FLAG "${COMMON_FLAG} -Wl,--warn-unresolved-symbols")
    set(COMMON_FLAG "${COMMON_FLAG} -Wl,-no-wchar-size-warning")

    if (("${PLATFORM}" STREQUAL "armeabi-v7a") AND (DEFINED ASR_ESR_SUPPORT))
        set(COMMON_FLAG "${COMMON_FLAG} -Wl,--wrap=srand -Wl,--wrap=rand -DUSE_WRAP_RAND")
    endif ()

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)

endfunction()
