# Changelog
Based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 4.0.7 - 2021-03-31
### Fixed
- Fix package installation bug for local development.

## 4.0.6 - 2021-03-31
### Fixed
- Fixed version bump bug for major and feature branches.

## 4.0.5 - 2021-03-31
### Fixed
- Feature and major branches do not need to have a `-` (`major-...` --> `major...`).
  This allows the use of `feature/`, `feature-` or any other separator (or none).

## 4.0.4 - 2021-03-30
### Fixed
- Subsequent projects did not use the latest package versions of requirements.

## 4.0.3 - 2021-03-30
### Fixed
- Append developer ID when not pushing onto the master branch.

## 4.0.2 - 2021-03-30
### Fixed
- Only print conan output if needed.

## 4.0.1 - 2021-03-30
### Fixed
- Several bug fixes to make the new workflow work with Gitlab.

## 4.0.0 - 2021-03-30
### Changed
- Remove feature branch support.

## 3.0.2 - 2021-03-17
### Added
- Added additional quick start guid and readme.

## 3.0.1 - 2021-03-05
### Fixed
- If on a `feature-...` branch, check if the package can be downloaded
  from channel `ci`. If not use the `develop` channel for that package.

## 3.0.0 - 2021-02-25
### Changed
- Change gitlab ci interface to support feature branch deployment.
  The branch structure needs to be:
  * `feature-...`
  * `develop`
  * `testing`
  * `master/main`

## 2.0.5 - 2021-02-10
### Changed
- Use unique docker conainer names.

## 2.0.4 - 2021-02-04
### Fixed
- Pass UNIQUE_BUILD_ID on to the container.

## 2.0.3 - 2021-02-04
### Fixed
- Fix CI conanfile.py bug.

## 2.0.2 - 2021-02-04
### Fixed
- Silence `upgrade-workflow` target.

## 2.0.1 - 2021-02-04
### Fixed
- Fix conanfile.py for multiple requirements.

## 2.0.0 - 2021-02-04
### Changes
- Need to indicate the usage of default conan user and channel explicitly
  (e.g. `name/1.2.3` -> `name/1.2.3@{user}/{channel}`).

## 1.4.0 - 2021-02-03
### Added
- Add support to keep the `.conan` folder in the project. This feature can be activated
  by setting CONAN_KEEP_PACKAGE.
- Make sure packages cannot be compiled on a main branch if
  the version already exists in the remote repo.
### Fixed
- Fixed `conanfile.py` config variables.

## 1.3.0 - 2021-01-28
### Added
- Also upload package aliases for 1.0.X and 1.0.0.X.

## 1.2.1 - 2021-01-26
### Added
- Make sure containers are stoped and removed before running a new instance.

## 1.2.0 - 2021-01-25
### Added
- Add PARENT_UNIQUE_BUILD_ID for multi-project pipelines.

## 1.1.0 - 2021-01-25
### Added
- Provide `INSTALLED_CONAN_PACKAGES` variable to list the currently installed conan packages.
- Provide `UNIQUE_BUILD_ID` to uniquely identify a build. This is useful for auto build systems.

## 1.0.0 - 2021-01-22
### Removed
- Remove test-package target.
### Fixed
- Also set linker options.

## 0.15.7 - 2021-01-13
### Fixed
- Fix IS_INSIDE_CONTAINER bug of some docker versions.

## 0.15.6 - 2021-01-13
### Fixed
- Pass GIT_BRANCH_NAME to container.

## 0.15.5 - 2021-01-12
### Fixed
- Fix syntax bug in tests/conanfile.py.

## 0.15.4 - 2021-01-12
### Fixed
- Set DEVELOPER_NAME to 'demo' by default for the CI/CD execution.

## 0.15.3 - 2021-01-11
### Fixed
- Use different download and upload conan channels for custom packages.
  This ensures that a developer can test changes in multiple packages.

## 0.15.2 - 2021-01-11
### Fixed
- Use conan environment variables as default values for missing config entries.

## 0.15.1 - 2021-01-08
### Fixed
- Fix default chanel insertion for public conan packages.

## 0.15.0 - 2021-01-07
### Added
- Add support for conan recipe aliases.

## 0.14.0 - 2020-12-17
### Added
- Support conan user channel overwrites.

## 0.13.1 - 2020-12-11
### Fixed
- Fix CMake interface include bug.

## 0.13.0 - 2020-12-10
### Added
- Support executing test scripts in the "tests" folder.

## 0.12.5 - 2020-12-02
### Changed
- Specify conan include folders as system include folders to suppress
  warnings of external dependencies.

## 0.12.4 - 2020-11-25
### Fixed
- CMake unit test configuration failed when the PROJECT_TYPE is EXECUTABLE.

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

