## This makefile adheres to the tset C++ developer workflow.
##
## ## Quick Start Guide
## 
## In case you clone an existing repo using the tset C++ workflow, this quickstart will help you set
## up your repo.
##
## ### Add a "secret" file in the root folder.
##
## Your "secret" file needs to contain a `CONAN_USER_PASSWORD` variable and nothing more. This is
## the password used to login into your conan repository. This should be already setup if you clone
## an existing repository. Usually this password is stored in the teams password manager. Search
## for "conan" in your password manager or ask your dev-ops team or admit for the password.
## ```sh
## CONAN_USER_PASSWORD=1234567890abcdefghijklmnopqrstuvwxyz
## ```
##
## ### Setup your `DEVELOPER_NAME`
##
## **LINUX:** In your ".bashrc" (or .zshrc or similar file depending on your linux shell) set the
## `DEVELOPER_NAME` variable to you developer name or initials.
## ```sh
## export DEVELOPER_NAME=mhe
## ```
##
## **WINDOWS:** Add `DEVELOPER_NAME` to your user variables. Set it to your developer name or
## initials.
##
## ### Working with the tset C++ workflow
##
## You can execute the following commands inside a shell in the root folder of the project:
## * `make`: Print a help for all the targets available.
## * `make release`: Release and `make debug` will start a development container and will compile
##                   the source code inside the docker container.
## * `make test`: Each project usually contains unit tests or test scripts to test the functionality
##                of the compiled package or program.
## * `make package`: Prepare a conan package in the "out" folder of the project.
## * `make upload`: Upload the conan package in from the "out" folder to the conan server.
## * `make shell`: You can also start a shell inside the container and execute all above commands
##                 within. This can be helpful to save compile time.
##
## ### Program execution inside the container
##
## Start a terminal inside the dev container using `make shell`. The binaries are located in
## "out/build/bin". Some projects also provide "start.sh" files in the "tests" folder, which can
## be executed to start a test service or other program for local testing. Have a look inside the
## "start.sh" file to get information about how to use these scripts.
##
## ## Introduction
##
## The tset C++ developer workflow expects a "config" and an optional "secret" and "Dockerfile"
## file in the same directory as this Makefile.
##
## ### The config file explained
##
## The "config" file contains a list of environment variables. These include the following:
##
## ```
## PROJECT_NAME=the-name-of-the-project
## PROJECT_URL=https://github.com/optional/path/to/repo.git
## PROJECT_DESCRIPTION="Optional project information."
## WORKFLOW_VERSION=4.0.9
## DOCKER_BASE_IMAGE=h3tch/dev-workflow:1.0.0
## DOCKER_IMAGE=the-name-of-the-image:latest
## CONAN_USER=username
## CONAN_SERVER_NAME=conan-server
## CONAN_SERVER_URL=http://localhost:9300
## CONAN_REQUIRE=boost/1.74.0,stdc/1.0.0@demo/stable,mathc/{latest}@{user}/{channel}
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
## | CONAN_REQUIRE      | Additional conan requirements as a comma separated list. 1.X indicates the most recent major version. {user} means CONAN_USER will be inserted here. {channel} means the conan channel will be inserted here. |
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
## Depending on which folders and files are present, an executable, shared library or header only
## library will be created.
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
## If there are `*.cpp` files in the `src` folder, but no `main.cpp`, a shared library will be
## created.
##
## **Header Only Library**
##
## A header only library will be assumed if neither the conditions for an executable nor a shared
## library are met.
##
## ### The Makefile Explained
##
## Please execute `make` in the root folder of the project to see the documentation of the make
## targets.
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
CURRENT_WORKFLOW_VERSION := 4.0.12
WORKFLOW_REPO ?= https://github.com/h3tch/tset-dev-workflow-conan.git

# VARIABLES

-include config
DEVELOPER_ID ?= 0
export COMPILE_OPTIONS
export PROJECT_NAME := $(or $(PROJECT_NAME),test-project)
export PROJECT_DIR := $(abspath .)
CONTAINER_NAME := $(PROJECT_NAME)-$(or $(PARENT_PIPELINE_ID),$(CI_PIPELINE_ID),$(DEVELOPER_ID))

ifeq ($(IS_INSIDE_CONTAINER), 1)
ifneq ($(filter release debug test package upload,$(MAKECMDGOALS)),)

    -include secret

    BUILD_OUT_DIR := $(PROJECT_DIR)/out/build
    SOURCE_OUT_DIR := $(PROJECT_DIR)/out/source
    TESTS_OUT_DIR := $(PROJECT_DIR)/out/tests
    PACKAGE_OUT_DIR := $(PROJECT_DIR)/out/package
    CI_CONFIG_FILE := out/ci.env
    CONAN_CONFIG_FILE := out/.env
    CONAN_USER := $(or $(FORCE_CONAN_USER),$(CONAN_USER),demo)
    CONAN_SERVER_NAME := $(or $(FORCE_CONAN_SERVER_NAME),$(CONAN_SERVER_NAME),local-conan)
    CONAN_SERVER_URL := $(or $(FORCE_CONAN_SERVER_URL),$(CONAN_SERVER_URL),http://localhost:9300)
    CONAN_USER_PASSWORD := $(or $(FORCE_CONAN_USER_PASSWORD),$(CONAN_USER_PASSWORD),$(CONAN_USER))
    CI_COMMIT_REF_NAME := $(or $(CI_COMMIT_REF_NAME),$(shell git symbolic-ref --short HEAD))
    CI_PIPELINE_ID := $(or $(CI_PIPELINE_ID),$(DEVELOPER_ID))
    PARENT_PIPELINE_ID := $(or $(PARENT_PIPELINE_ID),$(DEVELOPER_ID))
    PARENT_PROJECT_NAME := $(or $(PARENT_PROJECT_NAME),__NO_PARENT_PROJECT__)

    ensure_valid_version = $(shell echo $(word 1,$(subst ., ,$1))).$(shell echo $(word 2,$(subst ., ,$1))).$(shell echo $$(($(word 3,$(subst ., ,$1)))))

    find_next_free_version = $(shell found=1; \
        major=$(word 1,$(subst ., ,$1)); \
        minor=$(word 2,$(subst ., ,$1)); \
        patch=$(word 3,$(subst ., ,$1)); \
        while [[ $$found -ge 1 ]]; do \
            found=$$(conan download $(PROJECT_NAME)/$${major}.$${minor}.$${patch}@$(CONAN_USER)/stable -r $(CONAN_SERVER_NAME) -re &> /dev/null && echo 1 || echo 0); \
            if [[ $$found -ge 1 ]]; then \
                if [[ $2 -eq 1 ]]; then \
                    ((major = major + 1)); \
                    ((minor = 0)); \
                    ((patch = 0)); \
                elif [[ $2 -eq 2 ]]; then \
                    ((minor = minor + 1)); \
                    ((patch = 0)); \
                elif [[ $2 -eq 3 ]]; then \
                    ((patch = patch + 1)); \
                fi \
            fi; \
        done; \
        echo $${major}.$${minor}.$${patch})
    
    package_exists = $(shell conan download $1 -r $(CONAN_SERVER_NAME) -re &> /dev/null && echo 1)

    # Setup custom remote repo.
    CONAN_REMOTE_EXISTS := $(shell (conan remote list 2>/dev/null | grep -q tset-conan) && echo 1)
    ifneq ($(CONAN_REMOTE_EXISTS), 1)
        $(info Add Conan remote: $(CONAN_SERVER_NAME) -> $(CONAN_SERVER_URL))
        $(shell conan remote add $(CONAN_SERVER_NAME) $(CONAN_SERVER_URL))
    endif

    # Set conan user and password
    CONAN_USER_EXISTS := $(shell (conan user 2>/dev/null | grep tset-conan | grep None) && echo 1)
    ifneq ($(CONAN_USER_EXISTS), 1)
        $(info Set Conan user for $(CONAN_SERVER_NAME): $(CONAN_USER) $(if $(CONAN_USER_PASSWORD),(has password)))
        $(shell conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) &> /dev/null)
    endif

    # Setup local repo.
    ifneq ($(CONAN_KEEP_PACKAGE),)
        $(shell cp -r $(HOME)/.conan $(PROJECT_DIR))
        export CONAN_USER_HOME := $(PROJECT_DIR)
        $(info Set CONAN_USER_HOME: $(PROJECT_DIR))
    endif

    ifeq ($(CI_PIPELINE_SOURCE),push)
    ifeq ($(CI_COMMIT_REF_NAME),master)
        RELEASE_MODE := 1
    endif
    endif

    $(info Branch: $(CI_COMMIT_REF_NAME))
    $(info Event: $(if $(CI_PIPELINE_SOURCE),$(CI_PIPELINE_SOURCE),local development))

    # Get project versions

    ifeq ($(CI_PIPELINE_SOURCE),push)
        # get latest CI generated version from develop
        CUR_PROJECT_VERSION := $(or $(shell \
            conan inspect $(PROJECT_NAME)/latest.$(DEVELOPER_ID)@$(CONAN_USER)/develop -a alias -r tset-conan | \
            grep alias | grep -o -E '/[0-9.]+@' | cut -d "/" -f 2 | cut -d "@" -f 1), 0.0.0)
        NEW_PROJECT_VERSION := $(call ensure_valid_version,$(CUR_PROJECT_VERSION))
        NEW_PROJECT_VERSION_LATEST := latest
        CONAN_SRC_LATEST := latest
        CONAN_SRC_CHANNEL := stable
        CONAN_DST_CHANNEL := stable
    else ifeq ($(CI_PIPELINE_SOURCE),pipeline)
        ifeq ($(RELEASE_MODE),1)
            CUR_PROJECT_VERSION := $(or $(shell \
                conan inspect $(PROJECT_NAME)/latest@$(CONAN_USER)/stable -a alias -r tset-conan | \
                grep alias | grep -o -E '/[0-9.]+@' | cut -d "/" -f 2 | cut -d "@" -f 1), 0.0.0)
            NEW_PROJECT_VERSION := $(call find_next_free_version,$(CUR_PROJECT_VERSION),3)
            NEW_PROJECT_VERSION_LATEST := latest
            CONAN_PARENT_SRC_LATEST := latest
            CONAN_SRC_LATEST := latest
            CONAN_SRC_CHANNEL := stable
            CONAN_DST_CHANNEL := stable
        else
            NEW_PROJECT_VERSION := 0.0.$(PARENT_PIPELINE_ID)
            NEW_PROJECT_VERSION_CI := tmp.$(PARENT_PIPELINE_ID)
            CONAN_PARENT_SRC_LATEST := latest.$(PARENT_PIPELINE_ID)
            CONAN_SRC_LATEST := tmp.$(PARENT_PIPELINE_ID)
            CONAN_SRC_CHANNEL := develop
            CONAN_DST_CHANNEL := develop
        endif
    else # is merge request or developer
        # get latest version from stable
        CUR_PROJECT_VERSION := $(or $(shell \
            conan inspect $(PROJECT_NAME)/latest@$(CONAN_USER)/stable -a alias -r tset-conan | \
            grep alias | grep -o -E '/[0-9.]+@' | cut -d "/" -f 2 | cut -d "@" -f 1), 0.0.0)
        VERSION_BUMP_TARGET := $(if $(filter major%,$(CI_COMMIT_REF_NAME)),1,$(if $(filter feature%,$(CI_COMMIT_REF_NAME)),2,3))
        NEW_PROJECT_VERSION := $(call find_next_free_version,$(CUR_PROJECT_VERSION),$(VERSION_BUMP_TARGET)).$(DEVELOPER_ID)
        NEW_PROJECT_VERSION_LATEST := latest.$(DEVELOPER_ID)
        NEW_PROJECT_VERSION_CI := latest.$(CI_PIPELINE_ID)
        CONAN_SRC_LATEST := latest
        CONAN_SRC_CHANNEL := stable
        CONAN_DST_CHANNEL := develop
    endif
    $(info Version bump: $(CUR_PROJECT_VERSION) -> $(NEW_PROJECT_VERSION))

    CONAN_RECIPE := $(if $(NEW_PROJECT_VERSION),$(PROJECT_NAME)/$(NEW_PROJECT_VERSION)@$(CONAN_USER)/$(CONAN_DST_CHANNEL))
    CONAN_RECIPE_LATEST := $(if $(NEW_PROJECT_VERSION_LATEST),$(PROJECT_NAME)/$(NEW_PROJECT_VERSION_LATEST)@$(CONAN_USER)/$(CONAN_DST_CHANNEL))
    CONAN_RECIPE_CI := $(if $(NEW_PROJECT_VERSION_CI),$(PROJECT_NAME)/$(NEW_PROJECT_VERSION_CI)@$(CONAN_USER)/$(CONAN_DST_CHANNEL))

    $(info Upload recipes:)
    $(if $(CONAN_RECIPE),$(info - $(CONAN_RECIPE)))
    $(if $(CONAN_RECIPE_LATEST),$(info - $(CONAN_RECIPE_LATEST)))
    $(if $(filter-out $(CONAN_RECIPE_LATEST),$(CONAN_RECIPE_CI)),$(info - $(CONAN_RECIPE_CI)))

    # Make sure the packages do not exist
    ifeq ($(filter develop,$(CONAN_DST_CHANNEL)),)
    ifeq ($(if $(CONAN_RECIPE),$(call package_exists,$(CONAN_RECIPE))),1)
        $(info Warning: Package $(CONAN_RECIPE) already exists.)
    endif
    endif
endif
else
    # Is outside the container.
    ifeq (,$(wildcard config))
        $(info WARNING No 'config' file found.)
    endif

    CONTAINER_DIR := /workspaces/$(notdir $(CURDIR))
    PSEUDO_TTY := $(if $(DISABLE_TTY),,-t)
    DOCKER_BUILD_NO_CACHE ?= --no-cache
    DOCKER_RUN_COMMAND := docker run --rm -i $(PSEUDO_TTY) \
        --network host \
        -e IS_INSIDE_CONTAINER=1 \
        -e DEVELOPER_ID=$(DEVELOPER_ID) \
        -e PARENT_PIPELINE_ID=$(PARENT_PIPELINE_ID) \
        -e PARENT_PROJECT_NAME=$(PARENT_PROJECT_NAME) \
        -e CI_COMMIT_REF_NAME=$(CI_COMMIT_REF_NAME) \
        -e CI_PIPELINE_SOURCE=$(CI_PIPELINE_SOURCE) \
        -e CI_PIPELINE_ID=$(CI_PIPELINE_ID) \
        -e RELEASE_MODE=$(RELEASE_MODE) \
        -e CONAN_USER=$(CONAN_USER) \
        -e CONAN_USER_PASSWORD=$(CONAN_USER_PASSWORD) \
        -e FORCE_CONAN_USER=$(FORCE_CONAN_USER) \
        -e FORCE_CONAN_CHANNEL=$(FORCE_CONAN_CHANNEL) \
        -e FORCE_CONAN_SERVER_NAME=$(FORCE_CONAN_SERVER_NAME) \
        -e FORCE_CONAN_SERVER_URL=$(FORCE_CONAN_SERVER_URL) \
        -e FORCE_CONAN_USER_PASSWORD=$(FORCE_CONAN_USER_PASSWORD) \
        -e CONAN_KEEP_PACKAGE=$(CONAN_KEEP_PACKAGE) \
        -v $(PROJECT_DIR):$(CONTAINER_DIR) \
        -w=$(CONTAINER_DIR) \
        --name $(CONTAINER_NAME) \
        $(DOCKER_IMAGE)

endif

# $(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))


# MACROS

define generate_env_files
	mkdir -p out
	# Store the project information in the CONAN_CONFIG_FILE
	# which will be used when the package is installed by the user.
	echo PROJECT_NAME=$(PROJECT_NAME) > $(CONAN_CONFIG_FILE)
	echo PROJECT_VERSION=$(NEW_PROJECT_VERSION) >> $(CONAN_CONFIG_FILE)
	echo PROJECT_DESCRIPTION=$(PROJECT_DESCRIPTION) >> $(CONAN_CONFIG_FILE)
	echo PROJECT_URL=$(PROJECT_URL) >> $(CONAN_CONFIG_FILE)
	# Store the new CONAN_REQUIRE variable in the CONAN_CONFIG_FILE.
	conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME); \
	for PACKAGE in $$(echo $(CONAN_REQUIRE) | tr ',' ' '); do \
		USER_PACKAGE=$${PACKAGE/\{user\}/$(CONAN_USER)}; \
		CONAN_PACKAGE=$${USER_PACKAGE/\{channel\}/$(CONAN_SRC_CHANNEL)}; \
		if [[ $${CONAN_PACKAGE} == $(PARENT_PROJECT_NAME)* ]]; then \
			RECIPE=$${CONAN_PACKAGE/\{latest\}/$(CONAN_PARENT_SRC_LATEST)}; \
		else \
			RECIPE=$${CONAN_PACKAGE/\{latest\}/$(CONAN_SRC_LATEST)}; \
		fi; \
        conan download $${RECIPE} -r $(CONAN_SERVER_NAME) -re &> /dev/null; \
		if [ "$$?" != "0" ]; then \
			PACKAGE_NAME=$$(echo $${PACKAGE} | cut -d "/" -f 1); \
			RECIPE=$${PACKAGE_NAME}/latest@$(CONAN_USER)/stable; \
		fi; \
		if [ -z "$$NEW_CONAN_REQUIRE" ]; then \
			NEW_CONAN_REQUIRE=$${RECIPE}; \
		else \
			NEW_CONAN_REQUIRE=$${NEW_CONAN_REQUIRE},$${RECIPE}; \
		fi \
	done; \
	echo "CONAN_REQUIRE=$${NEW_CONAN_REQUIRE}" >> $(CONAN_CONFIG_FILE)

    # CI_CONFIG_FILE
	echo "RELEASE_MODE=$(RELEASE_MODE)" > $(CI_CONFIG_FILE)
	echo "PROJECT_NAME=$(PROJECT_NAME)" >> $(CI_CONFIG_FILE)
endef

define execute_make_target_in_container
	(docker stop $(CONTAINER_NAME) &> /dev/null && docker rm $(CONTAINER_NAME) &> /dev/null) \
		&& echo "Had to stop and remove container $(CONTAINER_NAME)." \
		|| echo "Run make $(1) in container $(CONTAINER_NAME)."
	$(DOCKER_RUN_COMMAND) /bin/bash -c "make $(1)"
endef

define conan_install
	conan install . --update -s build_type=$(1) --install-folder=$(BUILD_OUT_DIR)
endef

define conan_build
	mkdir -p $(BUILD_OUT_DIR) && echo $(1) > $(BUILD_OUT_DIR)/build_type \
	&& INSTALLED_CONAN_PACKAGES=$$(conan search | grep "/" | tr '\n' ';') conan build . --build-folder=$(BUILD_OUT_DIR)
endef

define conan_create_package
	conan package . --build-folder=$(BUILD_OUT_DIR) --package-folder=$(PACKAGE_OUT_DIR)
endef

define conan_upload_package
	conan user $(CONAN_USER) --password $(CONAN_USER_PASSWORD) -r $(CONAN_SERVER_NAME) \
	&& conan export-pkg . $(CONAN_USER)/$(CONAN_DST_CHANNEL) --force --package-folder=$(PACKAGE_OUT_DIR) \
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
.PHONY:  help build rebuild release debug test package test-package upload shell tidy upgrade-workflow vscode generate-readme
.SILENT: help build rebuild release debug test package test-package upload shell tidy upgrade-workflow vscode generate-readme

help: ## | Show this help.
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

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
	$(call generate_env_files)
	$(call conan_install,Release)
	$(call conan_build,Release)
endif

debug: ## | Compile and link the source code inside the container into binaries with debug symbols.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,debug)
else
	-rm -rf $(PROJECT_DIR)/out
	$(call generate_env_files)
	$(call conan_install,Debug)
	$(call conan_build,Debug)
endif

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

upload: ## | Upload the packages to the package server (needs a secret file with a `CONAN_USER_PASSWORD` or ` CONAN_USER_PASSWORD=<password: default CONAN_USER> make upload`). -- Requires: release/debug, package
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(call execute_make_target_in_container,upload)
else
	$(call conan_upload_package)
ifneq ($(CONAN_RECIPE_LATEST),)
	$(call conan_upload_alias,$(CONAN_RECIPE_LATEST))
endif
ifneq ($(filter-out $(CONAN_RECIPE_LATEST),$(CONAN_RECIPE_CI)),)
	$(call conan_upload_alias,$(CONAN_RECIPE_CI))
endif
endif

shell: ## | Start a terminal inside the container. This way you can save time when recompiling the source code.
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

vscode: ## | Start Visual Studio Code with all environment variables of the config file set. This will allow you to use the devcontainer extension if the .devcontainer folder is set up correctly.
ifneq ($(IS_INSIDE_CONTAINER), 1)
	$(shell cat $(PROJECT_DIR)/config) DOCKERFILE_PATH=$(or $(wildcard $(PROJECT_DIR)/Dockerfile), $(wildcard $(PROJECT_DIR)/.devcontainer/Dockerfile)) code .
else
	echo "Must be executed outside the container."
endif

generate-readme: ## | Compile a readme.md file from this Makefile. All lines starting with "##" will be included.
	cat Makefile | grep '^##' | cut -c 4- > readme.md
