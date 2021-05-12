cmake_minimum_required(VERSION 2.6)

PROJECT(pubmsg C)

INCLUDE(CheckFunctionExists)


FIND_PATH(uci_include_dir uci.h)

FIND_LIBRARY(udev NAMES udev)
FIND_LIBRARY(evdev NAMES evdev)
FIND_LIBRARY(lzo2 NAMES lzo2)
FIND_LIBRARY(mosquitto NAMES mosquitto)
FIND_LIBRARY(urcu-cds NAMES urcu-cds)
FIND_LIBRARY(urcu-common NAMES urcu-common)
FIND_LIBRARY(urcu NAMES urcu)
FIND_LIBRARY(curl NAMES curl)
FIND_LIBRARY(uci NAMES uci)
FIND_LIBRARY(mbedtls NAMES mbedtls)
FIND_LIBRARY(mbedx509 NAMES mbedx509)
FIND_LIBRARY(mbedcrypto NAMES mbedcrypto)
FIND_LIBRARY(ssl NAMES ssl)
FIND_LIBRARY(pthread NAMES pthread)
FIND_LIBRARY(ubox NAMES ubox)
FIND_LIBRARY(crypto NAMES crypto)


INCLUDE_DIRECTORIES(${uci_include_dir})

#ADD_DEFINITIONS(-Os -Wall  -Wextra --std=gnu99 -g3)
ADD_DEFINITIONS(-Os -Wall  --std=gnu99 -g3)
#ADD_DEFINITIONS(-Wno-unused-parameter -Wmissing-declarations)

set(CMAKE_VERBOSE_MAKEFILE ON)
aux_source_directory(. CURRENT_SRC)
aux_source_directory(./libdict/src DICT_SRC)
aux_source_directory(./libdfu DFU_SRC)
aux_source_directory(./libbase  BASE_SRC)

message(STATUS "CURRENT_SRC = ${CURRENT_SRC}")
message(STATUS "DICT_SRC = ${DICT_SRC}")
message(STATUS "DFU_SRC = ${DFU_SRC}")
message(STATUS "BASE_SRC = ${BASE_SRC}")

SET(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")

IF(APPLE)
  INCLUDE_DIRECTORIES(/opt/local/include)
  LINK_DIRECTORIES(/opt/local/lib)
ENDIF()

include_directories(./ 
./libdict/include 
./libbase
./libdfu
 )

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -std=gnu99")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-builtin-macro-redefined -D'__FILE__=\"$(subst $(realpath ${CMAKE_SOURCE_DIR})/,,$(abspath $<))\"'")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-builtin-macro-redefined -D'__FILE__=\"$(subst $(realpath ${CMAKE_SOURCE_DIR})/,,$(abspath $<))\"'")


ADD_EXECUTABLE(${PROJECT_NAME} ${CURRENT_SRC} ${DFU_SRC} ${DICT_SRC} ${BASE_SRC} )
TARGET_LINK_LIBRARIES(${PROJECT_NAME} ${urcu} ${pthread} ${ssl} ${lzo2} ${urcu-common} ${urcu-cds} ${mbedtls} ${mbedx509} ${mbedcrypto}  ${mosquitto} ${udev}  ${evdev} ${crypto} ${ubox} ${curl} ${uci})

INSTALL(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION sbin)
