project(PackageTest CXX)

get_target_property(PROJECT_TYPE $ENV{PROJECT_NAME} TYPE)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

enable_testing ()
include (GoogleTest)

file (GLOB CPP_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "$ENV{PROJECT_DIR}/src/*.cpp")
list (LENGTH CPP_FILES NUM_FILES)
list (LENGTH CONAN_LIBS NUM_LIBS)

list (APPEND REQUIRED_LINK_LIBRARIES gtest_main gtest pthread)
if (${NUM_LIBS})
    list (APPEND REQUIRED_LINK_LIBRARIES ${CONAN_LIBS})
endif ()
if (${NUM_FILES} AND NOT ${PROJECT_TYPE} MATCHES "EXECUTABLE")
    message (STATUS "PROJECT_TYPE: ${PROJECT_TYPE}")
    list (APPEND REQUIRED_LINK_LIBRARIES $ENV{PROJECT_NAME})
endif ()

if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/config.in")
    configure_file("config.in" "config.h")
elseif (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/config.in")
    configure_file("tests/config.in" "config.h")
endif ()

file (GLOB TEST_FILES "$ENV{PROJECT_DIR}/tests/test*.cpp")
foreach (file ${TEST_FILES})
    get_filename_component (name ${file} NAME_WE)
    add_executable (${name} ${file})
    add_dependencies (${name} $ENV{PROJECT_NAME})
    set_property(TARGET ${name} PROPERTY CXX_STANDARD 17)
    target_include_directories (${name} PRIVATE $ENV{PROJECT_DIR}/include ${CMAKE_CURRENT_BINARY_DIR} ${CONAN_INCLUDE_DIRS})
    target_link_libraries (${name} ${REQUIRED_LINK_LIBRARIES})
    gtest_discover_tests (${name})
endforeach ()
