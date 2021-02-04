# This file adheres to the tset C++ developer workflow.
# See the documentation in the Makefile for more information.
# Do not edit this file.

from conans import ConanFile, CMake
import glob
import os


class CppDevContainerTestConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "cmake"

    def __init__(self, *args, **kwargs):
        config = dict(load_config_file(os.path.join('out', '.env')))
        require = config.get('CONAN_REQUIRE', '')
        if require is not None and len(require) > 0:
            user = config.get('CONAN_USER', '')
            channel = config.get('CONAN_CHANNEL', '')
            CppDevContainerTestConan.requires = require.replace('{user}', user).replace('{channel}', channel).split(',')
        super().__init__(*args, **kwargs)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def test(self):
        for test_file in glob.glob(os.path.join("bin", "test*")):
            self.run(f"LD_LIBRARY_PATH={os.path.abspath('bin')} {test_file}")


def load_config_file(filename): 
    with open(filename) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue

            k, v = line.split('=', 1)
            k, v = k.strip(), v.strip()

            if len(v) > 0:
                quoted = v[0] == v[len(v) - 1] in ['"', "'"]
                if quoted:
                    v = v[1:-1]

            yield k, v
