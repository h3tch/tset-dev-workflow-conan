## This makefile adheres to the tset C++ developer workflow.

CURRENT_WORKFLOW_VERSION := 0.2.4
WORKFLOW_VERSION ?= $(CURRENT_WORKFLOW_VERSION)
WORKFLOW_REPO ?= https://github.com/h3tch/tset-dev-workflow-conan.git

export PROJECT_DIR := $(abspath .)
include config
SHELL = /bin/bash


# COMPILE VARIABLES

IS_INSIDE_CONTAINER := $(shell awk -F/ '$$2 == "docker"' /proc/self/cgroup | wc -l)
DOCKER_IMAGE_TAG ?= $(PROJECT_NAME):$(DOCKER_IMAGE_VERSION)
DOCKER_BUILD_NO_CACHE ?= --no-cache
DOCKER_RUN_COMMAND := docker run --rm -it \
	--network host \
	--env-file $(PROJECT_DIR)/config \
	-v $(PROJECT_DIR):/workspace \
	-w=/workspace \
	--name $(PROJECT_NAME) \
	$(DOCKER_IMAGE_TAG)

define execute_make_target_in_container
	$(DOCKER_RUN_COMMAND) /bin/bash -c "make $(1)"
endef


# CONAN MACROS

CONAN_PASSWORD ?= $(CONAN_USER)
CONAN_RECIPE := $(PROJECT_NAME)/$(PROJECT_VERSION)@$(CONAN_USER)/$(CONAN_CHANNEL)

define conan_compile_with_build_type
	-@rm -rf out
	@source config \
		&& conan source . \
			--source-folder=$(PROJECT_DIR)/out/source \
		&& conan install . --update -s build_type=$(1) \
			--install-folder=$(PROJECT_DIR)/out/build \
		&& conan build . \
			--source-folder=$(PROJECT_DIR)/out/source \
			--build-folder=$(PROJECT_DIR)/out/build
endef

define conan_create_package
	@source config \
		&& conan package . \
			--source-folder=$(PROJECT_DIR)/out/source \
			--build-folder=$(PROJECT_DIR)/out/build \
			--package-folder=$(PROJECT_DIR)/out/package
endef

define conan_test_package
	@source config \
		&& conan export-pkg . $(CONAN_USER)/$(CONAN_CHANNEL) \
			--package-folder=$(PROJECT_DIR)/out/package \
		&& conan test tests $(CONAN_RECIPE) \
			--test-build-folder=$(PROJECT_DIR)/out/tests
endef

define conan_upload_package
	@source config \
		&& conan user $(CONAN_USER) --password $(CONAN_PASSWORD) -r tset-conan \
		&& conan export-pkg . $(CONAN_USER)/$(CONAN_CHANNEL) \
			-f --package-folder=$(PROJECT_DIR)/out/package \
		&& conan upload $(CONAN_RECIPE) -r=tset-conan
endef


# MAKEFILE TARGETS

.DEFAULT_GOAL := help
.PHONY:  help build rebuild release debug test package test-package upload shell upgrade-developer-workflow
.SILENT: help build rebuild release debug test package test-package upload shell upgrade-developer-workflow

help: ## | Show this help.
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

rebuild: ## | Rebuild the docker container image (no cache).
ifeq ($(IS_INSIDE_CONTAINER), 0)
	docker build --rm $(DOCKER_BUILD_NO_CACHE) -t $(DOCKER_IMAGE_TAG) .
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

test: ## | Run the unit tests inside the container. -- Requires: compile
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,test)
else
	make --directory $(PROJECT_DIR)/out/build test
endif

package: ## | Build a conan package out of the binaries. -- Requires: compile
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,package)
else
	$(call conan_create_package)
endif

test-package: ## | Execute the unit test linking with the conan package. -- Requires: compile, package
ifeq ($(IS_INSIDE_CONTAINER), 0)
	$(call execute_make_target_in_container,test-package)
else
	$(call conan_test_package)
endif

upload: ## | Upload the packages to the package server. -- Requires: compile, package
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

upgrade-developer-workflow:
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
