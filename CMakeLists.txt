cmake_minimum_required (VERSION 3.16)
project ($ENV{PROJECT_NAME} VERSION $ENV{PROJECT_VERSION} LANGUAGES CXX)

# SETUP CONAN PACKAGE MANAGEMENT IN CMAKE

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

# CREATE A SHARED OBJECT OR HEADER ONLY LIBRARY

file (GLOB CPP_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.cpp)
list (LENGTH CPP_FILES NUM_FILES)

if (${NUM_FILES})
    add_library ($ENV{PROJECT_NAME} SHARED ${CPP_FILES})
else ()
    add_library ($ENV{PROJECT_NAME} INTERFACE)
endif ()

target_include_directories ($ENV{PROJECT_NAME} PUBLIC include PRIVATE src/include)

# ADD UNIT TESTS

include (tests/CMakeLists.txt) 
