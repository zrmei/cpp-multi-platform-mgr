cmake_minimum_required(VERSION 3.13)
SET(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS ON)
SET(CMAKE_COLOR_MAKEFILE ON)
CMAKE_POLICY(SET CMP0048 NEW)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

add_executable(main_demo main.cpp)

if (CMAKE_SYSTEM_NAME MATCHES "Android")
    target_link_libraries(main_demo dl)
endif ()