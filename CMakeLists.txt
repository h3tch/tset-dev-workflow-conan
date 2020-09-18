cmake_minimum_required (VERSION 3.16)
project ($ENV{PROJECT_NAME} VERSION $ENV{PROJECT_VERSION} LANGUAGES CXX)

# SETUP CONAN PACKAGE MANAGEMENT IN CMAKE

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

# CREATE A SHARED OBJECT OR HEADER ONLY LIBRARY

file (GLOB CPP_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.cpp)
list (LENGTH CPP_FILES NUM_FILES)

message(STATUS "CONAN_INCLUDE_DIRS: ${CONAN_INCLUDE_DIRS}")
message(STATUS "CONAN_LIB_DIRS: ${CONAN_LIB_DIRS}")
message(STATUS "CONAN_LIBS: ${CONAN_LIBS}")

if (${NUM_FILES})
    message (STATUS "Create a shared library")
    add_library ($ENV{PROJECT_NAME} SHARED ${CPP_FILES})
    target_include_directories ($ENV{PROJECT_NAME} PUBLIC include PRIVATE ${CONAN_INCLUDE_DIRS} src/include)
    target_link_directories ($ENV{PROJECT_NAME} PRIVATE ${CONAN_LIB_DIRS})
    target_link_libraries ($ENV{PROJECT_NAME} ${CONAN_LIBS})
else ()
    message (STATUS "Create a header only library")
    add_library ($ENV{PROJECT_NAME} INTERFACE)
    target_include_directories ($ENV{PROJECT_NAME} INTERFACE include ${CONAN_INCLUDE_DIRS})
endif ()

# ADD UNIT TESTS

include (tests/CMakeLists.txt) 
