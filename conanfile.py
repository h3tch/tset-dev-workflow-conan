from conans import ConanFile, CMake, tools
import glob
import os

current_directory = os.path.join(os.path.dirname(os.path.abspath(__file__)))
is_header_only_library = len(glob.glob("src/*")) == 0

class CppDevContainerConan(ConanFile):
    license = "Proprietary"
    generators = "cmake"
    exports = "config"
    exports_sources = "include/*", "src/*", "tests/*", "CMakeLists.txt", "LICENSE"
    options = {"shared": [True, False]}
    default_options = {"shared": True}

    def __init__(self, *args, **kwargs):
        config = dict(load_config_file(os.path.join(current_directory, 'config')))

        CppDevContainerConan.name = config['PROJECT_NAME']
        CppDevContainerConan.version = config['PROJECT_VERSION']
        CppDevContainerConan.description = config.get('PROJECT_DESCRIPTION', None)
        CppDevContainerConan.url = config.get('PROJECT_URL', None)

        if not is_header_only_library:
            CppDevContainerConan.settings = "os", "compiler", "build_type", "arch"

        CONAN_REQUIRE = config.get('CONAN_REQUIRE', '')
        CppDevContainerConan.requires = CONAN_REQUIRE.split(',') if len(CONAN_REQUIRE) > 0 else None

        super().__init__(*args, **kwargs)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
    
    def package(self):
        self.copy("*", dst="bin", src="bin", excludes=("test*", "*.so"))
        self.copy("*.h", dst="include", src="include")
        self.copy("*.so", dst="lib", src="lib", keep_path=False)

    def package_info(self):
        if os.path.exists('include'):
            self.cpp_info.includedirs = ["include"]
        if os.path.exists('lib'):
            self.cpp_info.libs = [CppDevContainerConan.name]
            self.env_info.LD_LIBRARY_PATH.append(os.path.join(self.package_folder, "lib"))
            self.env_info.DYLD_LIBRARY_PATH.append(os.path.join(self.package_folder, "lib"))

    def package_id(self):
        if is_header_only_library:
            self.info.header_only()
            
    def imports(self):
        self.copy("*", src="@bindirs", dst="bin")
        self.copy("*", src="@libdirs", dst="bin")


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
