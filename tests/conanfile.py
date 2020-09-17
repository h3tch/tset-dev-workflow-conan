from conans import ConanFile, CMake
import glob

class CppDevContainerTestConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "cmake"

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def test(self):
        for test_file in glob.glob("bin/test*"):
            self.run(test_file)
