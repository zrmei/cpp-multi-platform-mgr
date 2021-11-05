include(CheckCXXCompilerFlag)
include(CheckSymbolExists)

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
    SET(COMMON_FLAG "-w -pipe -fomit-frame-pointer -fPIC -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden -Bsymbolic")

    set(CMAKE_C_VISIBILITY_PRESET hidden PARENT_SCOPE)
    set(CMAKE_CXX_VISIBILITY_PRESET hidden PARENT_SCOPE)

    add_definitions(-DPOCO_STATIC -DPOCO_NO_AUTOMATIC_LIBS -DPOCO_OS_FAMILY_UNIX)

    CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)
    if (COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG " ${COMMON_FLAG} -Wl,--gc-sections")
    endif ()

    if (PLATFORM MATCHES "(x86|x64)")
        CHECK_CXX_COMPILER_FLAG("-static-libstdc++ -static-libgcc" COMPILER_SUPPORTS_STATIC_CXX)
        if (COMPILER_SUPPORTS_STATIC_CXX)
            set(COMMON_FLAG "${COMMON_FLAG} -static-libstdc++ -static-libgcc")
        endif ()
    endif ()

    CHECK_CXX_COMPILER_FLAG("-mfma" COMPILER_SUPPORTS_MFMA)
    if (COMPILER_SUPPORTS_MFMA)
        set(COMMON_FLAG "-mfma ${COMMON_FLAG}")
    endif ()

    CHECK_CXX_COMPILER_FLAG("-msse -mfpmath=sse" COMPILER_SUPPORTS_MSSE)
    if (COMPILER_SUPPORTS_MSSE)
        set(COMMON_FLAG "-msse -mfpmath=sse ${COMMON_FLAG}")
        add_definitions(-DUSE_SSE)
    endif ()

    set(TEXT_COMMAND_FLAG "-mfpu=neon -ftree-vectorize -mvectorize-with-neon-quad -mfloat-abi=softfp -ffast-math")
    CHECK_CXX_COMPILER_FLAG("${TEXT_COMMAND_FLAG}" COMPILER_SUPPORTS_ARM_NEON)
    if (COMPILER_SUPPORTS_ARM_NEON)
        set(COMMON_FLAG "${COMMON_FLAG} ${TEXT_COMMAND_FLAG}")
        add_definitions(-DUSE_NEON -DFLOAT_APPROX)
    endif ()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
    if (COMPILER_SUPPORTS_CXX14)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    elseif (COMPILER_SUPPORTS_CXX11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    else ()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif ()

    MESSAGE(STATUS "SIZE LENGTH " ${CMAKE_SIZEOF_VOID_P})

    IF (CMAKE_SIZEOF_VOID_P EQUAL 8)
        MESSAGE(STATUS "current platform: Linux  64")

        IF (PLATFORM STREQUAL "x86")
            MESSAGE(STATUS "build 32 bit lib in 64 os system")

            SET(COMMON_FLAG "${COMMON_FLAG} -m32")
        ENDIF (PLATFORM STREQUAL "x86")
    ELSE ()
        IF (PLATFORM STREQUAL "x64")
            MESSAGE(FATAL_ERROR "can not build 64bit on 32 os system")
        ENDIF ()
    ENDIF (CMAKE_SIZEOF_VOID_P EQUAL 8)

    CHECK_PTHREAD_SETNAME()

    SET(LINK_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/../libs/linux/${PLATFORM} PARENT_SCOPE)
    SET(AIUI_LIBRARY_TYPE ${PLATFORM} PARENT_SCOPE)

    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--exclude-libs,ALL")
    #set(COMMON_FLAG "${COMMON_FLAG} -Wl,--unresolved-symbols=ignore-in-shared-libs")
    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--warn-unresolved-symbols")
    set(COMMON_FLAG "${COMMON_FLAG} -Wl,-no-wchar-size-warning")
    
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
endfunction()

macro(source_group_by_dir abs_cur_dir source_files)
    if (MSVC)
        set(sgbd_cur_dir ${${abs_cur_dir}})
        foreach(sgbd_file ${${source_files}})
            string(REGEX REPLACE ${sgbd_cur_dir}/\(.*\) \\1 sgbd_fpath ${sgbd_file})
            string(REGEX REPLACE "\(.*\)/.*" \\1 sgbd_group_name ${sgbd_fpath})
            string(COMPARE EQUAL ${sgbd_fpath} ${sgbd_group_name} sgbd_nogroup)
            string(REPLACE "/" "\\" sgbd_group_name ${sgbd_group_name})
            if(sgbd_nogroup)
                set(sgbd_group_name "\\")
            endif(sgbd_nogroup)
            source_group(${sgbd_group_name} FILES ${sgbd_file})
        endforeach(sgbd_file)
    endif (MSVC)
endmacro(source_group_by_dir)

function(CheckForWindowsPlatform)
    IF (MSVC)
        SET(COMMON_FLAG "-w /utf-8 /nologo /Gm- /O2 /Ob2 /errorReport:prompt /WX- /Zc:wchar_t /Zc:inline /Zc:forScope /GR /Gd /Oy- /MT /EHsc /MP")

        CHECK_CXX_COMPILER_FLAG("/std:c++latest" COMPILER_SUPPORTS_CXXLATEST)
        CHECK_CXX_COMPILER_FLAG("/std:c++11" COMPILER_SUPPORTS_CXX11)
        if (COMPILER_SUPPORTS_CXX11)
            set(COMMON_FLAG "${COMMON_FLAG} /std:c++11")
        elseif (COMPILER_SUPPORTS_CXXLATEST)
            set(COMMON_FLAG "${COMMON_FLAG} /std:c++latest")
        endif (COMPILER_SUPPORTS_CXX11)

        if (PLATFORM MATCHES "(x86|x64)")
            add_definitions(-DUSE_SSE)
        endif ()

        add_definitions(-D_WIN32_WINNT=0x0501)

        # It is very important for windows linker to ignore the redefined sysmbols between poco and msvc
        #/FORCE:MULTIPLE
        SET(CMAKE_STATIC_LINKER_FLAGS "/FORCE:MULTIPLE /NODEFAULTLIB:library" PARENT_SCOPE)
        SET(CMAKE_SHARED_LINKER_FLAGS "/FORCE:MULTIPLE /NODEFAULTLIB:library" PARENT_SCOPE)
    ENDIF (MSVC)

    add_definitions(-DPOCO_STATIC -DPOCO_NO_AUTOMATIC_LIBS -DPOCO_OS_FAMILY_WINDOWS)

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /Os" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Os" PARENT_SCOPE)
endfunction()


function(CheckForAndroidPlatform)
    SET(COMMON_FLAG " -w -Os -fPIC -ffunction-sections -fdata-sections -fvisibility=hidden")

    CHECK_CXX_COMPILER_FLAG("-Wl,--gc-sections" COMPILER_SUPPORTS_GC_SECTIONS)
    if (COMPILER_SUPPORTS_GC_SECTIONS)
        set(COMMON_FLAG "-Wl,--gc-sections ${COMMON_FLAG}")
    endif ()

    CHECK_CXX_COMPILER_FLAG("-static-libstdc++ -static-libgcc" COMPILER_SUPPORTS_STATIC_CXX)
    if (COMPILER_SUPPORTS_STATIC_CXX)
        set(COMMON_FLAG "-static-libstdc++ -static-libgcc ${COMMON_FLAG}")
    endif ()

    CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
    CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
    if (COMPILER_SUPPORTS_CXX14)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    elseif (COMPILER_SUPPORTS_CXX11)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    else ()
        message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
    endif ()

    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--exclude-libs,ALL")
    #set(COMMON_FLAG "${COMMON_FLAG} -Wl,--unresolved-symbols=ignore-in-shared-libs")
    set(COMMON_FLAG "${COMMON_FLAG} -Wl,--warn-unresolved-symbols")
    set(COMMON_FLAG "${COMMON_FLAG} -Wl,-no-wchar-size-warning")

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAG}" PARENT_SCOPE)

    SET(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)
    SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -s" PARENT_SCOPE)

endfunction()
