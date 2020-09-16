from conans import ConanFile, CMake, tools
import glob
import os


PROJECT_NAME = os.environ['PROJECT_NAME']
PROJECT_VERSION = os.environ['PROJECT_VERSION']
PROJECT_URL = os.environ.get('PROJECT_URL', None)
PROJECT_DESCRIPTION = os.environ.get('PROJECT_DESCRIPTION', None)


class CppDevContainerConan(ConanFile):
    name = PROJECT_NAME
    version = PROJECT_VERSION
    license = "Proprietary"
    url = PROJECT_URL
    description = PROJECT_DESCRIPTION
    settings = "os", "compiler", "build_type", "arch"
    generators = "cmake"
    exports_sources = "include/*", "src/*", "tests/*", "Makefile", "Dockerfile", "config", "LICENSE", "CMakeLists.txt"

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
    
    def package(self):
        self.copy("*", dst="bin", src="bin", excludes="test*")
        self.copy("*.h", dst="include", src="include")
        self.copy("*.a", dst="lib", keep_path=False)
        self.copy("*.so", dst="lib", keep_path=False)

    def package_info(self):
        if os.path.exists("include"):
            self.cpp_info.includedirs = ["include"]
        if os.path.exists("src"):
            self.cpp_info.libs = [PROJECT_NAME]
    
    def deploy(self):
        self.copy("*", dst="bin", src="bin")
        self.copy("*", dst="bin", src="lib")
