# ===MAKEFILE CONFS===
.PHONY: init setup install update run clean build help 
.DEFAULT_GOAL := help
# DEBUG MAKEFILE?
# Q :=  # ON
Q := @# OFF

# ===MULTIPLATFORM SETUP===
ifeq ($(OS),Windows_NT)# Shell commands setup
RM_CMD := rmdir /S /Q
else
RM_CMD := rm -r
endif

# ===PROGRAM SETUP===
NAME := Placeholder
VENV ?= .venv# Default venv name
UV ?= uv


init: setup install
	$Qecho "Done!"

setup:
	$Qecho "Setting up virtual environment..."
	$Q$(UV) venv $(VENV)
	
install:
	$Qecho "Installing $(NAME) and dependencies..."
	$Q$(UV) sync
install-%:
	$Qecho "Installing $* dependencies..."
	$Q$(UV) sync --extra $*
	
update:
	$Qecho "Updating..."
	$Q$(UV) sync --upgrade

run:
	$Q$(UV) run -m $(NAME) --locked
	
clean:
	$Q$(RM_CMD) dist/
	$Q$(RM_CMD) build/

build:
	$Qecho "Building $(NAME)..."
	$Q$(UV) run -m PyInstaller $(NAME).spec

help:
	$Qecho "Usage: make [TARGET] [VENV=<venv name>]"
	$Qecho "Targets:"
	$Qecho "	help		- Shows this message."
	$Qecho "	init		- Initializes environment for development."
	$Qecho "	install		- Installs the project as a module and runtime dependencies."
	$Qecho "	install-<name>	- Installs optional dependencies group."
	$Qecho "			Example: make install-dev"
	$Qecho "	update		- Upgrades all installed modules"
	$Qecho "	run		- Runs the project module. ($(NAME))"
	$Qecho "	build		- Builds distributable. (requires PyInstaller package)"
	$Qecho "	clean		- Cleans all the build artifacts."