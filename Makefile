## This makefile adheres to the tset C++ developer workflow.
##
## It expects a "config" and an optional "Dockerfile" file in the same directory as this Makefile.
##
## ### The config file explained
##
## The "config" file contains a list of environment variables. These include the following:
##
## ```
## PROJECT_NAME=the-name-of-the-project
## PROJECT_VERSION=1.0.0
## PROJECT_URL=https://github.com/optional/path/to/repo.git
## PROJECT_DESCRIPTION="Optional project information."
## WORKFLOW_VERSION=0.2.11
## DOCKER_BASE_IMAGE=tset-conan-base:1.0.0
## DOCKER_IMAGE=the-name-of-the-image:latest
## CONAN_USER=username
## CONAN_SERVER_NAME=conan-server
## CONAN_CHANNEL=testing
## CONAN_REQUIRE=boost/1.74.0,tset-stdc/1.0.0@tset/stable
## ```
##
## Most of these variables should be self-explaining. Some will be described in detail:
##
## | Variable Name     | Description |
## |-------------------|-------------|
## | WORKFLOW_VERSION  | The tset developer workflow version to be used. When you execute `make upgrade-developer-workflow`, this version will be downloaded. Note that this will overwrite the existing dev workflow files. |
## | DOCKER_BASE_IMAGE | The docker base image name to be passed to `docker build` as a `build-arg`. Note, that all dev images shoud in some way be derived from the "tset-conan-base" image. |
## | DOCKER_IMAGE      | The docker image to be created by the build target and used by the other targets (release, test, package, ...). |
## | CONAN_USER        | The conan user for package search and upload. |
## | CONAN_SERVER_NAME | The name of the conan server from where to down and upload internal packages. |
## | CONAN_CHANNEL     | The conan channel from where to down and upload internal packages. |
## | CONAN_REQUIRE     | Additional conan requirements as a comma separated list. |
## 
## ### The Dockerfile explained
## 
## The `Dockerfile` needs to start with the following lines
## ```
## ARG DOCKER_BASE_IMAGE
## FROM ${DOCKER_BASE_IMAGE}
## ```
## Note that the current user will be `coder`. To install package you might need
## to switch to the `root` user. But make sure that in the end `coder` is the user
## again.
## 
## ### The required project layout
## 
## The following directory layout is required by this dev workflow:
##
## ```
## <project-root>
##  - [include]          # Optional public headers to be deployed in the package.
##  | - *.h
##  | - *.hpp
##  - [src]              # Optional source files of the shared library or executable.
##  | - *.cpp
##  - tests              # Unit test folder containing cpp GTest files.
##  | - CMakeLists.txt   # Predefined by the dev workflow.
##  | - conanfile.py     # Predefined by the dev workflow.
##  | - test-*.cpp
##  - CMakeLists.txt     # Predefined by the dev workflow.
##  - config
##  - Dockerfile
##  - conanfile.py       # Predefined by the dev workflow.
##  - Makefile           # Predefined by the dev workflow.
## ```
##
## Depending on which folders and files are present, an executable, shared library or header only library will be created.
##
## **Executable**
##
## If there is a `main.cpp` file in the `src` folder, an executable project will be assumed.
##
## **Shared Library**
##
## If there are `*.cpp` files in the `src` folder, but no `main.cpp`, a shared library will be created.
##
## **Header Only Library**
##
## A header only library will be assumed if neither the conditions for an executable nor a shared library are met.
##
## ### The Makefile Explained
##
## Please execute `make` in the root folder of the project to see the documentation of the make targets.

SHELL = /bin/bash
CURRENT_WORKFLOW_VERSION := 0.2.15
WORKFLOW_VERSION ?= $(CURRENT_WORKFLOW_VERSION)
WORKFLOW_REPO ?= https://github.com/h3tch/tset-dev-workflow-conan.git

export PROJECT_DIR := $(abspath .)
include config


# COMPILE VARIABLES

CONAN_USER_PASSWORD ?= $(CONAN_USER)
CONAN_RECIPE := $(PROJECT_NAME)/$(PROJECT_VERSION)@$(CONAN_USER)/$(CONAN_CHANNEL)
IS_INSIDE_CONTAINER := $(shell awk -F/ '$$2 == "docker"' /proc/self/cgroup | wc -l)
DOCKER_BUILD_NO_CACHE ?= --no-cache
DOCKER_RUN_COMMAND := docker run --rm -it \
	--network host \
	--env-file $(PROJECT_DIR)/config \
	-v $(PROJECT_DIR):/workspace \
	-w=/workspace \
	--name $(PROJECT_NAME) \
	$(DOCKER_IMAGE)

define execute_make_target_in_container
	$(DOCKER_RUN_COMMAND) /bin/bash -c "make $(1)"
endef


# CONAN MACROS

define conan_compile_with_build_type
	-rm -rf out
	source config \
		&& conan source . \
			--source-folder=$(PROJECT_DIR)/out/source \
		&& conan install . \
			--update -s build_type=$(1) \
			--install-folder=$(PROJECT_DIR)/out/build \
		&& conan build . \
			--source-folder=$(PROJECT_DIR)/out/source \
			--build-folder=$(PROJECT_DIR)/out/build
endef

define conan_create_package
	source config \
		&& conan package . \
			--source-folder=$(PROJECT_DIR)/out/source \
			--build-folder=$(PROJECT_DIR)/out/build \
			--package-folder=$(PROJECT_DIR)/out/package
endef

define conan_test_package
	source config \
		&& conan export-pkg . $(CONAN_USER)/$(CONAN_CHANNEL) \
			--force --package-folder=$(PROJECT_DIR)/out/package \
		&& conan test tests $(CONAN_RECIPE) \
			--test-build-folder=$(PROJECT_DIR)/out/tests
endef

define conan_upload_package
	source config \
		&& conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) \
		&& conan export-pkg . $(CONAN_USER)/$(CONAN_CHANNEL) \
			--force --package-folder=$(PROJECT_DIR)/out/package \
		&& conan upload $(CONAN_RECIPE) -r=$(CONAN_SERVER_NAME) --all --check
endef


# MAKEFILE TARGETS

.DEFAULT_GOAL := help
.PHONY:  help build rebuild release debug test package test-package upload shell upgrade-developer-workflow
.SILENT: help build rebuild release debug test package test-package upload shell upgrade-developer-workflow

help: ## | Show this help.
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

rebuild: ## | Rebuild the docker container image (no cache).
ifeq ($(IS_INSIDE_CONTAINER), 0)
	[ -f $(PROJECT_DIR)/Dockerfile ] \
	&& docker build \
		--rm $(DOCKER_BUILD_NO_CACHE) \
		--tag $(DOCKER_IMAGE) \
		--build-arg DOCKER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) . \
	|| echo "No Dockerfile found. Skipping docker build."
else
	echo "Must be executed outside the container."
endif

build: DOCKER_BUILD_NO_CACHE:=
build: rebuild; ## | Build the docker container image, but use the cache for already successful build stages.

clean: ## | Delete the out folder.
	-rm -rf out

release: ## | Compile and link the source code inside the container into binaries.
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,release)
else
	$(call conan_compile_with_build_type,Release)
endif

debug: ## | Compile and link the source code inside the container into binaries with debug symbols.
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,debug)
else
	$(call conan_compile_with_build_type,Debug)
endif

test: ## | Run the unit tests inside the container. -- Requires: release/debug
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,test)
else
	LD_LIBRARY_PATH=$(PROJECT_DIR)/out/build/bin make --directory $(PROJECT_DIR)/out/build test
endif

package: ## | Build a conan package out of the binaries. -- Requires: release/debug
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,package)
else
	$(call conan_create_package)
endif

test-package: ## | Execute the unit test linking with the conan package. -- Requires: release/debug, package
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,test-package)
else
	$(call conan_test_package)
endif

upload: ## | Upload the packages to the package server (` CONAN_USER_PASSWORD=<password: default CONAN_USER> make upload`). -- Requires: release/debug, package
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,upload)
else
	$(call conan_upload_package)
endif

shell: ## | Start a terminal inside the container.
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(DOCKER_RUN_COMMAND) /bin/bash
else
	echo "You are already inside the container."
endif

upgrade-developer-workflow: ## | Upgrade to a different developer workfow version.
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,upgrade-developer-workflow)
else ifneq ($(WORKFLOW_VERSION), $(CURRENT_WORKFLOW_VERSION))
	echo "Upgrade developer workflow from $(CURRENT_WORKFLOW_VERSION) to $(WORKFLOW_VERSION)."
	git config --global advice.detachedHead false
	git clone --quiet --depth 1 --branch $(WORKFLOW_VERSION) $(WORKFLOW_REPO) /tmp/dev-workflow \
		&& cd /tmp/dev-workflow \
		&& find . -name 'conanfile.py' -exec cp --parents '{}' /$(PROJECT_DIR) \; \
		&& find . -name 'CMakeLists.txt' -exec cp --parents '{}' /$(PROJECT_DIR) \; \
		&& find . -name 'Makefile' -exec cp --parents '{}' /$(PROJECT_DIR) \;
	rm -rf /tmp/dev-workflow
endif
