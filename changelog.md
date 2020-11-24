# Changelog
Based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 0.12.3 - 2020-11-24
### Fixed
- Install conan dependencies before executing clang-tidy.

## 0.12.2 - 2020-11-24
### Fixed
- Fix clang-tidy target. Use the wildcard function to find the source files.

## 0.12.1 - 2020-11-24
### Fixed
- Pass environment variables to cmake every time it is called. This way environment
  variables can be changed inside a container without restarting it.

## 0.12.0 - 2020-11-24
### Added
- Add clang-tidy make target to check all source files in ./src and ./tests.

## 0.11.0 - 2020-11-23
### Added
- Enable compile options through environment variable COMPILE_OPTIONS.

## 0.10.0
### Added
- Add precompiled header support.

## 0.9.0
### Added
- Add overwrite conan variables support. Add disable TTY support.

## 0.8.5
### Fixed
- Add src/include folder to include list.

## 0.8.4
### Fixed
- Pass conan login data to the container.

## 0.8.3
### Fixed
- Auto login before calling conan install and export-pkg.

## 0.8.2
### Added
- Load env variables from a secret file if it exists.

## 0.8.1
### Fixed
- Fix conan command not found bug.

## 0.8.0
### Added
- Install conan remotes.
- User docker hub to get the workflow container.

## 0.7.2
### Fixed
- Fix copy workflow files bug.

## 0.7.1
### Changed
- Do not return an error if there is nothing to be done during make debug.

## 0.7.0
### Changed
- Only rebuild on make debug if there where changes in the code or the previous build type was release.
### Added
- Add a default Dockerfile in case the repo using this workflow does not provide one.

## 0.6.0
### Added
- Create a compile_command.json file when building with cmake.

## 0.5.0
### Added
- Add Visual Studio Code remote container support.

## 0.4.1
### Changed
- Do not copy sources into the build folder.

## 0.3.0
### Changed
- Only recompile on debug if the source files are newer than the build output.

## 0.2.16
### Added
- Use the folder /workspaces instead of /workspace.
- CMake configure *.in files in include, src and tests.
- Support executables and *.in configuration files.
- Also package hpp files.
- Fix build and test issues for shared library dependecies.
- Fix header only library support.
- Added upgrade-developer-workflow Makefile target to allow workflow updates.

## 0.1.0
### Added
- Basic developer workflow without dependency support.
