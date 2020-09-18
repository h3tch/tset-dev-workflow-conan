project(PackageTest CXX)

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
if (${NUM_FILES})
    list (APPEND REQUIRED_LINK_LIBRARIES $ENV{PROJECT_NAME})
endif ()

file (GLOB TEST_FILES "$ENV{PROJECT_DIR}/tests/test*.cpp")
foreach (file ${TEST_FILES})
    get_filename_component (name ${file} NAME_WE)
    add_executable (${name} ${file})
    add_dependencies (${name} $ENV{PROJECT_NAME})
    target_include_directories (${name} PRIVATE $ENV{PROJECT_DIR}/include ${CONAN_INCLUDE_DIRS})
    target_link_libraries (${name} ${REQUIRED_LINK_LIBRARIES})
    gtest_discover_tests (${name})
endforeach ()
