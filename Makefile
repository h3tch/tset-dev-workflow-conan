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
## WORKFLOW_VERSION=2.0.0
## DOCKER_BASE_IMAGE=h3tch/dev-workflow:1.0.0
## DOCKER_IMAGE=the-name-of-the-image:latest
## CONAN_USER=username
## CONAN_SERVER_NAME=conan-server
## CONAN_SERVER_URL=http://localhost:9300
## CONAN_CHANNEL=testing
## CONAN_REQUIRE=boost/1.74.0,stdc/1.0.0@demo/stable,mathc/1.X@{user}/{channel}
## CONAN_KEEP_PACKAGE=1
## ```
##
## Most of these variables should be self-explaining. Some will be described in detail:
##
## | Variable Name      | Description |
## |--------------------|-------------|
## | WORKFLOW_VERSION   | The developer workflow version to be used. When you execute `make upgrade-developer-workflow`, this version will be downloaded. Note that this will overwrite the existing dev workflow files. |
## | DOCKER_BASE_IMAGE  | The docker base image name to be passed to `docker build` as a `build-arg`. Note, that all dev images should in some way be derived from the "tset-conan-base" image. |
## | DOCKER_IMAGE       | The docker image to be created by the build target and used by the other targets (release, test, package, ...). |
## | CONAN_USER         | The conan user for package search and upload. |
## | CONAN_SERVER_NAME  | The name of the conan server from where to down and upload internal packages. |
## | CONAN_SERVER_URL   | The url of the conan server from where to down and upload internal packages. |
## | CONAN_CHANNEL      | The conan channel from where to down and upload internal packages. |
## | CONAN_REQUIRE      | Additional conan requirements as a comma separated list. 1.X indicates the most recent major version. {user} means CONAN_USER will be inserted here. {channel} means CONAN_CHANNEL will be inserted here. |
## | CONAN_KEEP_PACKAGE | The conan repository path will be set the the root folder of the project. The repository will hence not be deleted when the container closes. |
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
##  | - [include]        # Optional private headers included at compile time.
##  | | - [pch.h]        # Optional pricompiled header to be included in *.cpp files.
##  | - *.cpp
##  - tests              # Unit test folder containing cpp GTest files.
##  | - [include]        # Optional private headers included at compile time.
##  | | - [test-pch.h]   # Optional pricompiled header to be included in test-*.cpp files.
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
## If precompiled headers `pch.h` or `test-pch.h` are present they will be automatically 
## included in all source and test files respectively.
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
## 
## **Overwrite Environment Variables**
## The following variables can be overwritten by adding a `FORCE_` in front. E.g.
## ```
## FORCE_CONAN_SERVER_NAME=my-conan \
## FORCE_CONAN_SERVER_URL=https://repo.myconan.io \
## FORCE_CONAN_USER=Yoda \
## FORCE_CONAN_USER_PASSWORD=not_admin \
## FORCE_CONAN_CHANNEL=stable \
## make release
## ```

SHELL = /bin/bash
CURRENT_WORKFLOW_VERSION := 2.0.4
WORKFLOW_VERSION ?= $(CURRENT_WORKFLOW_VERSION)
WORKFLOW_REPO ?= https://github.com/h3tch/tset-dev-workflow-conan.git

export PROJECT_DIR := $(abspath .)
BUILD_OUT_DIR := $(PROJECT_DIR)/out/build
SOURCE_OUT_DIR := $(PROJECT_DIR)/out/source
TESTS_OUT_DIR := $(PROJECT_DIR)/out/tests
PACKAGE_OUT_DIR := $(PROJECT_DIR)/out/package
CONTAINER_DIR := /workspaces/$(notdir $(CURDIR))
DOCKERFILE_PATH := $(or $(wildcard $(PROJECT_DIR)/Dockerfile), $(wildcard $(PROJECT_DIR)/.devcontainer/Dockerfile))
ifeq (,$(wildcard config))
$(info WARNING No 'config' file found.)
endif
-include config
export
-include secret


# COMPILE VARIABLES

DEVELOPER_NAME ?= demo
UNIQUE_BUILD_ID := $(or $(PARENT_UNIQUE_BUILD_ID),$(UNIQUE_BUILD_ID),0)
PROJECT_NAME := $(or $(PROJECT_NAME),test-project)
PROJECT_VERSION := $(or $(PROJECT_VERSION),1.0.0).$(UNIQUE_BUILD_ID)
PROJECT_MAJOR_VERSION_ALIAS := $(shell echo $(PROJECT_VERSION) | grep -o -E '[0-9]+' | head -1).X
PROJECT_MINOR_VERSION_ALIAS := $(shell echo $(PROJECT_VERSION) | grep -o -E '[0-9]+\.[0-9]' | head -1).X
PROJECT_PATCH_VERSION_ALIAS := $(shell echo $(PROJECT_VERSION) | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' | head -1).X

ifeq ($(GIT_BRANCH_NAME),)
	GIT_BRANCH_NAME := $(shell git symbolic-ref --short HEAD)
endif
ifeq ($(GIT_BRANCH_NAME), master)
	IS_ON_A_MAIN_BRANCH := 1
	DEFAULT_CONAN_CHANNEL := stable
else ifeq ($(GIT_BRANCH_NAME), main)
	IS_ON_A_MAIN_BRANCH := 1
	DEFAULT_CONAN_CHANNEL := stable
else ifeq ($(GIT_BRANCH_NAME), testing)
	IS_ON_A_MAIN_BRANCH := 1
	DEFAULT_CONAN_CHANNEL := testing
else ifeq ($(GIT_BRANCH_NAME), develop)
	IS_ON_A_MAIN_BRANCH := 1
	DEFAULT_CONAN_CHANNEL := develop
else
	DEFAULT_CONAN_CHANNEL := develop
	DEFAULT_CONAN_UPLOAD_CHANNEL := $(DEVELOPER_NAME)
endif

ifeq ($(DEFAULT_CONAN_UPLOAD_CHANNEL),demo)
$(info WARNING Using fallback conan upload channel 'demo'. Please export variable DEVELOPER_NAME to use a personal developer channel.)
endif

CONAN_CONFIG_FILE := out/.env
CONAN_USER := $(or $(FORCE_CONAN_USER),$(CONAN_USER),demo)
CONAN_CHANNEL := $(or $(FORCE_CONAN_CHANNEL),$(CONAN_CHANNEL),$(DEFAULT_CONAN_CHANNEL))
CONAN_SERVER_NAME := $(or $(FORCE_CONAN_SERVER_NAME),$(CONAN_SERVER_NAME),local-conan)
CONAN_SERVER_URL := $(or $(FORCE_CONAN_SERVER_URL),$(CONAN_SERVER_URL),http://localhost:9300)
CONAN_USER_PASSWORD := $(or $(FORCE_CONAN_USER_PASSWORD),$(CONAN_USER_PASSWORD),$(CONAN_USER))
CONAN_UPLOAD_CHANNEL := $(or $(FORCE_CONAN_UPLOAD_CHANNEL),$(DEFAULT_CONAN_UPLOAD_CHANNEL),$(DEFAULT_CONAN_CHANNEL))
CONAN_RECIPE := $(PROJECT_NAME)/$(PROJECT_VERSION)@$(CONAN_USER)/$(CONAN_UPLOAD_CHANNEL)
CONAN_RECIPE_MAJOR_ALIAS := $(if $(PROJECT_MAJOR_VERSION_ALIAS),$(PROJECT_NAME)/$(PROJECT_MAJOR_VERSION_ALIAS)@$(CONAN_USER)/$(CONAN_UPLOAD_CHANNEL),)
CONAN_RECIPE_MINOR_ALIAS := $(if $(PROJECT_MINOR_VERSION_ALIAS),$(PROJECT_NAME)/$(PROJECT_MINOR_VERSION_ALIAS)@$(CONAN_USER)/$(CONAN_UPLOAD_CHANNEL),)
CONAN_RECIPE_PATCH_ALIAS := $(if $(PROJECT_PATCH_VERSION_ALIAS),$(PROJECT_NAME)/$(PROJECT_PATCH_VERSION_ALIAS)@$(CONAN_USER)/$(CONAN_UPLOAD_CHANNEL),)
PSEUDO_TTY := $(if $(DISABLE_TTY),,-t)
DOCKER_BUILD_NO_CACHE ?= --no-cache
DOCKER_RUN_COMMAND := docker run --rm -i $(PSEUDO_TTY) \
	--network host \
	--env-file $(PROJECT_DIR)/config \
	-e GIT_BRANCH_NAME=$(GIT_BRANCH_NAME) \
	-e DEVELOPER_NAME=$(DEVELOPER_NAME) \
	-e IS_INSIDE_CONTAINER=1 \
	-e CONAN_USER=$(CONAN_USER) \
	-e CONAN_USER_PASSWORD=$(CONAN_USER_PASSWORD) \
	-e CONAN_CHANNEL=$(CONAN_CHANNEL) \
	-e CONAN_KEEP_PACKAGE=$(CONAN_KEEP_PACKAGE) \
	-e UNIQUE_BUILD_ID=$(UNIQUE_BUILD_ID) \
	-v $(PROJECT_DIR):$(CONTAINER_DIR) \
	-w=$(CONTAINER_DIR) \
	--name $(PROJECT_NAME) \
	$(DOCKER_IMAGE)

# $(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))


# SETUP CONAN REPO

ifeq ($(IS_INSIDE_CONTAINER), 1)

# Setup custom remote repo.
CONAN_REMOTE_EXISTS := $(shell (conan remote list 2>/dev/null | grep -q tset-conan) && echo 1)
ifneq ($(CONAN_REMOTE_EXISTS), 1)
$(shell conan remote add $(CONAN_SERVER_NAME) $(CONAN_SERVER_URL))
endif # ($(CONAN_REMOTE_EXISTS), 1)

# Setup local repo.
ifneq ($(CONAN_KEEP_PACKAGE),)
$(shell cp -r $(HOME)/.conan $(CONTAINER_DIR))
export CONAN_USER_HOME := $(CONTAINER_DIR)
endif # ($(CONAN_KEEP_PACKAGE),)

# Make sure we do not overwrite a package in a main-branch.
ifeq ($(IS_ON_A_MAIN_BRANCH), 1)
PAKAGE_ALREADY_EXISTS := $(shell \
	conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) &> /dev/null \
	&& conan download $(CONAN_RECIPE) -r $(CONAN_SERVER_NAME) -re &> /dev/null && echo 1)
endif # ($(IS_ON_A_MAIN_BRANCH), 1)

endif # ($(IS_INSIDE_CONTAINER), 1)


# MACROS

define generate_conan_env_file
	mkdir -p out
	echo PROJECT_NAME=$(PROJECT_NAME) > $(CONAN_CONFIG_FILE)
	echo PROJECT_VERSION=$(PROJECT_VERSION) >> $(CONAN_CONFIG_FILE)
	echo PROJECT_DESCRIPTION=$(PROJECT_DESCRIPTION) >> $(CONAN_CONFIG_FILE)
	echo PROJECT_URL=$(PROJECT_URL) >> $(CONAN_CONFIG_FILE)
	echo CONAN_USER=$(CONAN_USER) >> $(CONAN_CONFIG_FILE)
	echo CONAN_CHANNEL=$(CONAN_CHANNEL) >> $(CONAN_CONFIG_FILE)
	echo CONAN_REQUIRE=$(CONAN_REQUIRE) >> $(CONAN_CONFIG_FILE)
endef

define execute_make_target_in_container
	(docker stop $(PROJECT_NAME) &> /dev/null && docker rm $(PROJECT_NAME) &> /dev/null) \
		&& echo "Had to stop and remove container $(PROJECT_NAME)." \
		|| echo "Run make $(1) in container $(PROJECT_NAME)."
	$(DOCKER_RUN_COMMAND) /bin/bash -c "make $(1)"
endef

define conan_install
	conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) \
	&& conan install . \
		--update -s build_type=$(1) \
		--install-folder=$(BUILD_OUT_DIR)
endef

define conan_build
	conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) \
	&& mkdir -p $(BUILD_OUT_DIR) && echo $(1) > $(BUILD_OUT_DIR)/build_type \
	&& INSTALLED_CONAN_PACKAGES=$$(conan search | grep "/" | tr '\n' ';') conan build . --build-folder=$(BUILD_OUT_DIR)
endef

define conan_create_package
	conan package . \
		--build-folder=$(BUILD_OUT_DIR) \
		--package-folder=$(PACKAGE_OUT_DIR)
endef

define conan_upload_package
	conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) \
	&& conan export-pkg . $(CONAN_USER)/$(CONAN_UPLOAD_CHANNEL) \
	    --force --package-folder=$(PACKAGE_OUT_DIR) \
	&& conan upload $(CONAN_RECIPE) -r=$(CONAN_SERVER_NAME) --all --check
endef

define conan_upload_alias
	if [[ ! -z "$(1)" ]]; then \
		conan alias $(1) $(CONAN_RECIPE); \
	    conan upload $(1) -r=$(CONAN_SERVER_NAME) --all --check; \
	else \
	    echo -e "\033[33mCannot upload alias $(1).\033[0m"; \
	fi
endef


# TARGETS

.DEFAULT_GOAL := help
.PHONY:  help build rebuild release debug test package test-package upload shell tidy upgrade-workflow vscode
.SILENT: help build rebuild release debug test package test-package upload shell tidy upgrade-workflow vscode

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
ifeq ($(PAKAGE_ALREADY_EXISTS), 1)
	echo -e "\033[31mThe conan package $(CONAN_RECIPE) already exists.\033[0m"
else
	$(call generate_conan_env_file)
	$(call conan_install,Release)
	$(call conan_build,Release)
endif # ($(PAKAGE_ALREADY_EXISTS), 1)
endif # ($(IS_INSIDE_CONTAINER), 1)

debug: ## | Compile and link the source code inside the container into binaries with debug symbols.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,debug)
else
	-rm -rf $(PROJECT_DIR)/out
ifeq ($(PAKAGE_ALREADY_EXISTS), 1)
	echo -e "\033[31mThe conan package $(CONAN_RECIPE) already exists.\033[0m"
else
	$(call generate_conan_env_file)
	$(call conan_install,Debug)
	$(call conan_build,Debug)
endif # ($(PAKAGE_ALREADY_EXISTS), 1)
endif # ($(IS_INSIDE_CONTAINER), 1)

test: ## | Run the unit tests inside the container. -- Requires: release/debug
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,test)
else
	LD_LIBRARY_PATH=$(BUILD_OUT_DIR)/bin make --directory $(BUILD_OUT_DIR) test
	for filename in $(PROJECT_DIR)/tests/test*.sh; do \
		[ -e "$${filename}" ] || continue; \
		echo -e "\033[1m`basename $${filename}`\033[0m ... START"; \
		$${filename} || exit 1; \
	done
endif

package: ## | Build a conan package out of the binaries. -- Requires: release/debug
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,package)
else
	$(call conan_create_package)
endif

upload: ## | Upload the packages to the package server (` CONAN_USER_PASSWORD=<password: default CONAN_USER> make upload`). -- Requires: release/debug, package
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,upload)
else
	$(call conan_upload_package)
	$(call conan_upload_alias,$(CONAN_RECIPE_MAJOR_ALIAS))
	$(call conan_upload_alias,$(CONAN_RECIPE_MINOR_ALIAS))
	$(call conan_upload_alias,$(CONAN_RECIPE_PATCH_ALIAS))
endif

shell: ## | Start a terminal inside the container.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(DOCKER_RUN_COMMAND) /bin/bash
else
	echo "You are already inside the container."
endif

tidy: ## | Run clang-tidy on the source files in "src" and "tests". -- Requires: release/debug
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,tidy)
else
	$(call conan_install,Release)
	clang-tidy -p=out/build $(wildcard src/*.cpp) $(wildcard tests/*.cpp)
endif

upgrade-workflow: ## | Upgrade to a different developer workflow version.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,upgrade-workflow)
else ifneq ($(WORKFLOW_VERSION), $(CURRENT_WORKFLOW_VERSION))
	echo "Upgrade developer workflow from $(CURRENT_WORKFLOW_VERSION) to $(WORKFLOW_VERSION)."
	git config --global advice.detachedHead false
	git clone --quiet --depth 1 --branch $(WORKFLOW_VERSION) $(WORKFLOW_REPO) /tmp/dev-workflow \
		&& cd /tmp/dev-workflow \
		&& find . -type f \( -not -name "LICENSE" -not -name "readme.md" -not -name "changelog.md" -not -path "./.git/*" \) -exec cp --parents '{}' /$(PROJECT_DIR) \;
	rm -rf /tmp/dev-workflow
endif

vscode: ## | Start Visual Studio Code with all environment variables of the config file set.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(shell cat $(PROJECT_DIR)/config) DOCKERFILE_PATH=$(DOCKERFILE_PATH) code .
else
	echo "Must be executed outside the container."
endif
