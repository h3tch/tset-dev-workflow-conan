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
## WORKFLOW_VERSION=0.8.0
## DOCKER_BASE_IMAGE=h3tch/dev-workflow:1.0.0
## DOCKER_IMAGE=the-name-of-the-image:latest
## CONAN_USER=username
## CONAN_SERVER_NAME=conan-server
## CONAN_SERVER_URL=http://localhost:9300
## CONAN_CHANNEL=testing
## CONAN_REQUIRE=boost/1.74.0,tset-stdc/1.0.0@tset/stable
## ```
##
## Most of these variables should be self-explaining. Some will be described in detail:
##
## | Variable Name     | Description |
## |-------------------|-------------|
## | WORKFLOW_VERSION  | The tset developer workflow version to be used. When you execute `make upgrade-developer-workflow`, this version will be downloaded. Note that this will overwrite the existing dev workflow files. |
## | DOCKER_BASE_IMAGE | The docker base image name to be passed to `docker build` as a `build-arg`. Note, that all dev images should in some way be derived from the "tset-conan-base" image. |
## | DOCKER_IMAGE      | The docker image to be created by the build target and used by the other targets (release, test, package, ...). |
## | CONAN_USER        | The conan user for package search and upload. |
## | CONAN_SERVER_NAME | The name of the conan server from where to down and upload internal packages. |
## | CONAN_SERVER_URL  | The url of the conan server from where to down and upload internal packages. |
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
CURRENT_WORKFLOW_VERSION := 0.8.2
WORKFLOW_VERSION ?= $(CURRENT_WORKFLOW_VERSION)
WORKFLOW_REPO ?= https://github.com/h3tch/tset-dev-workflow-conan.git

export PROJECT_DIR := $(abspath .)
BUILD_OUT_DIR := $(PROJECT_DIR)/out/build
SOURCE_OUT_DIR := $(PROJECT_DIR)/out/source
TESTS_OUT_DIR := $(PROJECT_DIR)/out/tests
PACKAGE_OUT_DIR := $(PROJECT_DIR)/out/package
CONTAINER_DIR := /workspaces/$(notdir $(CURDIR))
LATEST_BUILD_TYPE := $(shell cat $(BUILD_OUT_DIR)/build_type 2>/dev/null | head -n1 | cut -d " " -f1)
DOCKERFILE_PATH := $(or $(wildcard $(PROJECT_DIR)/Dockerfile), $(wildcard $(PROJECT_DIR)/.devcontainer/Dockerfile))
include config
-include secret


# COMPILE VARIABLES

CONAN_SERVER_NAME ?= local-conan
CONAN_SERVER_URL ?= http://localhost:9300
CONAN_USER ?= demo
CONAN_USER_PASSWORD ?= $(CONAN_USER)
CONAN_RECIPE := $(PROJECT_NAME)/$(PROJECT_VERSION)@$(CONAN_USER)/$(CONAN_CHANNEL)
CONAN_REMOTE_EXISTS := $(shell (conan remote list 2>/dev/null | grep -q tset-conan) && echo 1)
IS_INSIDE_CONTAINER := $(shell counter=$$(awk -F/ '$$2 == "docker"' /proc/self/cgroup | wc -l); if [ $$counter -gt 0 ]; then echo 1; fi)
DOCKER_BUILD_NO_CACHE ?= --no-cache
DOCKER_RUN_COMMAND := docker run --rm -it \
	--network host \
	--env-file $(PROJECT_DIR)/config \
	-v $(PROJECT_DIR):$(CONTAINER_DIR) \
	-w=$(CONTAINER_DIR) \
	--name $(PROJECT_NAME) \
	$(DOCKER_IMAGE)

older_than = $(shell if [[ "$$(find $(1) -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -f2- -d" ")" -ot "$$(find $(2) -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -f2- -d" ")" ]]; then echo 1; fi)
HAS_UPDATE_IN_INCLUDE := $(call older_than,$(BUILD_OUT_DIR),$(PROJECT_DIR)/include)
HAS_UPDATE_IN_SRC := $(call older_than,$(BUILD_OUT_DIR),$(PROJECT_DIR)/src)
HAS_UPDATE_IN_TESTS := $(call older_than,$(BUILD_OUT_DIR),$(PROJECT_DIR)/tests)
HAS_UPDATE = $(or $(HAS_UPDATE_IN_INCLUDE),$(HAS_UPDATE_IN_SRC),$(HAS_UPDATE_IN_TESTS))
NEEDS_REBUILD = $(if $(or $(filter Release,$(LATEST_BUILD_TYPE)), $(filter 1,$(HAS_UPDATE))),1,)

define execute_make_target_in_container
	$(DOCKER_RUN_COMMAND) /bin/bash -c "make $(1)"
endef


# CONAN MACROS

ifeq ($(IS_INSIDE_CONTAINER), 1)
ifneq ($(CONAN_REMOTE_EXISTS), 1)
$(shell conan remote add $(CONAN_SERVER_NAME) $(CONAN_SERVER_URL))
endif
endif

define conan_compile_with_build_type
	source config \
		&& conan install . \
			--update -s build_type=$(1) \
			--install-folder=$(BUILD_OUT_DIR) \
		&& conan build . \
			--build-folder=$(BUILD_OUT_DIR) \
		&& echo $(1) > $(BUILD_OUT_DIR)/build_type
endef

define conan_create_package
	source config \
		&& conan package . \
			--build-folder=$(BUILD_OUT_DIR) \
			--package-folder=$(PACKAGE_OUT_DIR)
endef

define conan_test_package
	source config \
		&& conan export-pkg . $(CONAN_USER)/$(CONAN_CHANNEL) \
			--force --package-folder=$(PACKAGE_OUT_DIR) \
		&& conan test tests $(CONAN_RECIPE) \
			--test-build-folder=$(TESTS_OUT_DIR)
endef

define conan_upload_package
	source config \
		&& conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) \
		&& conan export-pkg . $(CONAN_USER)/$(CONAN_CHANNEL) \
			--force --package-folder=$(PACKAGE_OUT_DIR) \
		&& conan upload $(CONAN_RECIPE) -r=$(CONAN_SERVER_NAME) --all --check
endef


# MAKEFILE TARGETS

.DEFAULT_GOAL := help
.PHONY:  help build rebuild release debug test package test-package upload shell upgrade-developer-workflow
.SILENT: help build rebuild release debug test package test-package upload shell upgrade-developer-workflow

help: ## | Show this help.
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

rebuild: ## | Rebuild the docker container image (no cache).
ifneq ($(IS_INSIDE_CONTAINER), 1)
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
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,release)
else
	-rm -rf $(PROJECT_DIR)/out
	$(call conan_compile_with_build_type,Release)
endif

debug: ## | Compile and link the source code inside the container into binaries with debug symbols.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,debug)
else ifeq ($(NEEDS_REBUILD), 1)
	-rm -rf $(PROJECT_DIR)/out
	$(call conan_compile_with_build_type,Debug)
else
	echo "Nothing to do."
endif

test: ## | Run the unit tests inside the container. -- Requires: release/debug
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,test)
else
	LD_LIBRARY_PATH=$(BUILD_OUT_DIR)/bin make --directory $(BUILD_OUT_DIR) test
endif

package: ## | Build a conan package out of the binaries. -- Requires: release/debug
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,package)
else
	$(call conan_create_package)
endif

test-package: ## | Execute the unit test linking with the conan package. -- Requires: release/debug, package
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,test-package)
else
	$(call conan_test_package)
endif

upload: ## | Upload the packages to the package server (` CONAN_USER_PASSWORD=<password: default CONAN_USER> make upload`). -- Requires: release/debug, package
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,upload)
else
	$(call conan_upload_package)
endif

shell: ## | Start a terminal inside the container.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(DOCKER_RUN_COMMAND) /bin/bash
else
	echo "You are already inside the container."
endif

upgrade-developer-workflow: ## | Upgrade to a different developer workflow version.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,upgrade-developer-workflow)
else ifneq ($(WORKFLOW_VERSION), $(CURRENT_WORKFLOW_VERSION))
	echo "Upgrade developer workflow from $(CURRENT_WORKFLOW_VERSION) to $(WORKFLOW_VERSION)."
	git config --global advice.detachedHead false
	git clone --quiet --depth 1 --branch $(WORKFLOW_VERSION) $(WORKFLOW_REPO) /tmp/dev-workflow \
		&& cd /tmp/dev-workflow \
		&& find . -type f \( -not -name "LICENSE" -not -path "./.git/*" \) -exec cp --parents '{}' /$(PROJECT_DIR) \;
	rm -rf /tmp/dev-workflow
endif

vscode: ## | Start Visual Studio Code with all environment variables of the config file set.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(shell cat $(PROJECT_DIR)/config) DOCKERFILE_PATH=$(DOCKERFILE_PATH) code .
else
	echo "Must be executed outside the container."
endif
