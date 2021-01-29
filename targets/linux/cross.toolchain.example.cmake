# this is required
SET(CMAKE_SYSTEM_NAME Linux)

# remove can not support libs
add_definitions(-DPTHREAD_SETNAME_NOT_SUPPORTED -DPOCO_NO_FPENVIRONMENT)

SET(CROSS_ROOT_PATH /opt/arm-himix100-linux)

# specify the cross compiler
SET(CMAKE_C_COMPILER   ${CROSS_ROOT_PATH}/bin/arm-himix100-linux-gcc)
SET(CMAKE_CXX_COMPILER ${CROSS_ROOT_PATH}/bin/arm-himix100-linux-g++)

SET(TOOL_ROOT_PATH ${CROSS_ROOT_PATH}/liteos_target/)

# where is the target environment
SET(CMAKE_FIND_ROOT_PATH  ${TOOL_ROOT_PATH} ${TOOL_ROOT_PATH}include ${TOOL_ROOT_PATH}lib)

# search for programs in the build host directories (not necessary)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
