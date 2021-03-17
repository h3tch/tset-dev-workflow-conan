This makefile adheres to the tset C++ developer workflow.

## Quick Start Guide

In case you clone an existing repo using the tset C++ workflow, this quickstart will help you set
up your repo.

### Add a "secret" file in the root folder.

Your "secret" file needs to contain a `CONAN_USER_PASSWORD` variable and nothing more. This is
the password used to login into your conan repository. This should be already setup if you clone
an existing repository. Usually this password is stored in the teams password manager. Search
for "conan" in your password manager or ask your dev-ops team or admit for the password.
```sh
CONAN_USER_PASSWORD=1234567890abcdefghijklmnopqrstuvwxyz
```

### Setup your `DEVELOPER_NAME`

**LINUX:** In your ".bashrc" (or .zshrc or similar file depending on your linux shell) set the
`DEVELOPER_NAME` variable to you developer name or initials.
```sh
export DEVELOPER_NAME=mhe
```

**WINDOWS:** Add `DEVELOPER_NAME` to your user variables. Set it to your developer name or
initials.

### Working with the tset C++ workflow

You can execute the following commands inside a shell in the root folder of the project:
* `make`: Print a help for all the targets available.
* `make release`: Release and `make debug` will start a development container and will compile
                  the source code inside the docker container.
* `make test`: Each project usually contains unit tests or test scripts to test the functionality
               of the compiled package or program.
* `make package`: Prepare a conan package in the "out" folder of the project.
* `make upload`: Upload the conan package in from the "out" folder to the conan server.
* `make shell`: You can also start a shell inside the container and execute all above commands
                within. This can be helpful to save compile time.

### Program execution inside the container

Start a terminal inside the dev container using `make shell`. The binaries are located in
"out/build/bin". Some projects also provide "start.sh" files in the "tests" folder, which can
be executed to start a test service or other program for local testing. Have a look inside the
"start.sh" file to get information about how to use these scripts.

## Introduction

The tset C++ developer workflow expects a "config" and an optional "secret" and "Dockerfile"
file in the same directory as this Makefile.

### The config file explained

The "config" file contains a list of environment variables. These include the following:

```
PROJECT_NAME=the-name-of-the-project
PROJECT_VERSION=1.0.0
PROJECT_URL=https://github.com/optional/path/to/repo.git
PROJECT_DESCRIPTION="Optional project information."
WORKFLOW_VERSION=2.0.0
DOCKER_BASE_IMAGE=h3tch/dev-workflow:1.0.0
DOCKER_IMAGE=the-name-of-the-image:latest
CONAN_USER=username
CONAN_SERVER_NAME=conan-server
CONAN_SERVER_URL=http://localhost:9300
CONAN_CHANNEL=testing
CONAN_REQUIRE=boost/1.74.0,stdc/1.0.0@demo/stable,mathc/1.X@{user}/{channel}
CONAN_KEEP_PACKAGE=1
```

Most of these variables should be self-explaining. Some will be described in detail:

| Variable Name      | Description |
|--------------------|-------------|
| WORKFLOW_VERSION   | The developer workflow version to be used. When you execute `make upgrade-developer-workflow`, this version will be downloaded. Note that this will overwrite the existing dev workflow files. |
| DOCKER_BASE_IMAGE  | The docker base image name to be passed to `docker build` as a `build-arg`. Note, that all dev images should in some way be derived from the "tset-conan-base" image. |
| DOCKER_IMAGE       | The docker image to be created by the build target and used by the other targets (release, test, package, ...). |
| CONAN_USER         | The conan user for package search and upload. |
| CONAN_SERVER_NAME  | The name of the conan server from where to down and upload internal packages. |
| CONAN_SERVER_URL   | The url of the conan server from where to down and upload internal packages. |
| CONAN_CHANNEL      | The conan channel from where to down and upload internal packages. |
| CONAN_REQUIRE      | Additional conan requirements as a comma separated list. 1.X indicates the most recent major version. {user} means CONAN_USER will be inserted here. {channel} means CONAN_CHANNEL will be inserted here. |
| CONAN_KEEP_PACKAGE | The conan repository path will be set the the root folder of the project. The repository will hence not be deleted when the container closes. |

### The Dockerfile explained

The `Dockerfile` needs to start with the following lines
```
ARG DOCKER_BASE_IMAGE
FROM ${DOCKER_BASE_IMAGE}
```
Note that the current user will be `coder`. To install package you might need
to switch to the `root` user. But make sure that in the end `coder` is the user
again.

### The required project layout

The following directory layout is required by this dev workflow:

```
<project-root>
 - [include]          # Optional public headers to be deployed in the package.
 | - *.h
 | - *.hpp
 - [src]              # Optional source files of the shared library or executable.
 | - [include]        # Optional private headers included at compile time.
 | | - [pch.h]        # Optional pricompiled header to be included in *.cpp files.
 | - *.cpp
 - tests              # Unit test folder containing cpp GTest files.
 | - [include]        # Optional private headers included at compile time.
 | | - [test-pch.h]   # Optional pricompiled header to be included in test-*.cpp files.
 | - CMakeLists.txt   # Predefined by the dev workflow.
 | - conanfile.py     # Predefined by the dev workflow.
 | - test-*.cpp
 - CMakeLists.txt     # Predefined by the dev workflow.
 - config
 - Dockerfile
 - conanfile.py       # Predefined by the dev workflow.
 - Makefile           # Predefined by the dev workflow.
```

Depending on which folders and files are present, an executable, shared library or header only
library will be created.

If precompiled headers `pch.h` or `test-pch.h` are present they will be automatically 
included in all source and test files respectively.

**Executable**

If there is a `main.cpp` file in the `src` folder, an executable project will be assumed.

**Shared Library**

If there are `*.cpp` files in the `src` folder, but no `main.cpp`, a shared library will be
created.

**Header Only Library**

A header only library will be assumed if neither the conditions for an executable nor a shared
library are met.

### The Makefile Explained

Please execute `make` in the root folder of the project to see the documentation of the make
targets.

**Overwrite Environment Variables**
The following variables can be overwritten by adding a `FORCE_` in front. E.g.
```
FORCE_CONAN_SERVER_NAME=my-conan \
FORCE_CONAN_SERVER_URL=https://repo.myconan.io \
FORCE_CONAN_USER=Yoda \
FORCE_CONAN_USER_PASSWORD=not_admin \
FORCE_CONAN_CHANNEL=stable \
make release
```
