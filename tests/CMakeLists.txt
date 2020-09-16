project(PackageTest CXX)

include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

enable_testing ()
include (GoogleTest)

file (GLOB TEST_FILES "$ENV{PROJECT_DIR}/tests/test*.cpp")
foreach (file ${TEST_FILES})
    get_filename_component (name ${file} NAME_WE)
    add_executable (${name} ${file})
    add_dependencies (${name} $ENV{PROJECT_NAME})
    target_link_libraries (${name} gtest_main gtest pthread $ENV{PROJECT_NAME})
    gtest_discover_tests (${name})
endforeach ()
