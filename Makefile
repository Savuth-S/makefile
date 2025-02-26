# ===MAKEFILE CONFS===
# DEBUG MAKEFILE?
# Q := # ON
Q := @# OFF
# DEFAULT TASK
.DEFAULT_GOAL := help
# MAKES SURE THESE ALWAYS GETS RUN
.PHONY: help build run clean linux windows x64

# ===MULTIPLATFORM SETUP===
PLATFORM ?= linux# Default platform
ARCH ?= x64# Default architecture

ifeq ($(OS),Windows_NT)# Shell commands setup
MKDIR_CMD := mkdir
RM_CMD := del /Q /S
CP_CMD := copy
else
MKDIR_CMD := mkdir -p
RM_CMD := rm -r
CP_CMD := cp
endif

# ===PROGRAM SETUP===
NAME:= Boards

OUT_PATH:= bin
OBJ_PATH:= obj

MODULES = src/main src/debug
ifeq ($(OS),Windows_NT)# gets all source files including subdirs
SOURCES:= $(shell cmd /V:ON /C "for /F %%A in ('dir /A-D /B /S $(MODULES)') \
		  do ( \
			set fullpath=%%A && \
			set relativepath=!fullpath:*$(MODULES)\=$(MODULES)\! && \
			echo !relativepath! \
			)" \
		  )
else
SOURCES:= $(shell find $(MODULES) -name "*.cpp")
endif
OBJS = $(SOURCES:%.cpp=$(OBJ_PATH)/$(PLATFORM)/$(ARCH)/%.o)
DEPS = $(OBJS:.o=.d)
-include $(DEPS)

ifeq ($(OS),Windows_NT)# gets all included subdirs
INCLUDE := $(shell (for /F "delims=" %%D in ('dir /AD /B /S ./include') do @echo %%D) & echo src/include)
else
INCLUDE := $(shell find src/include -type d)
endif
INCLUDE := $(INCLUDE:%=-I%)
INCLUDE += -Isrc/
LIBS :=
FLAGS := -Wall \
	   -Wextra \
	   -Wconversion \
	   -Wpedantic \
	   -Wmaybe-uninitialized \
	   -D_NAME=\"$(NAME)\" \
	   -D_DEBUG
	   # -D_RELEASE


setup:
	$Qecho "Making for $(PLATFORM)-$(ARCH)"
	$Q$(MKDIR_CMD) "${OBJ_PATH}/${PLATFORM}/${ARCH}"

ifeq ($(OS),Windows_NT)
	for %%M in ($(MODULES)) do ( \
		for /D %%D in (%%M\\*) do ( \
			$(MKDIR_CMD) "$(OBJ_PATH)/$(PLATFORM)/$(ARCH)/%%D" \
		) \
	)
else
	$Q$(MKDIR_CMD) "${OBJ_PATH}/${PLATFORM}/${ARCH}"

	$Qfor module in $(MODULES); do \
		find $$module -type d | while read subfolder; do \
			$(MKDIR_CMD) ${OBJ_PATH}/${PLATFORM}/${ARCH}/$$subfolder; \
		done; \
	done
endif

	$Q$(MKDIR_CMD) "${OUT_PATH}/${PLATFORM}/${ARCH}"

# Platform/Architecture specific setups
linux: $(ARCH)
	$Qecho "Setting up $@ environment..."
	$(eval CC:= g++)
	$Qecho Set compiler as $(CC)...

DLLS_PATH := /usr/x86_64-w64-mingw32/bin
DLLS := libgcc_s_seh-1 libstdc++-6 libwinpthread-1
DLLS := $(DLLS:%=%.dll)
windows: $(ARCH) $(DLLS)
	$Qecho "Setting up $@ environment..."
	$(eval CC:= x86_64-w64-mingw32-g++)
	$Qecho Set compiler as $(CC)...
%.dll:
	$Qecho "Copying DLL $@.."
	$Q$(CP_CMD) "$(DLLS_PATH)/$@" "${OUT_PATH}/${PLATFORM}/${ARCH}"


build: setup $(PLATFORM) $(OBJS)
	$Qecho Assembling $(NAME)...
	$Q${CC} ${FLAGS} $(OBJS) ${LIBS} -o ${OUT_PATH}/${PLATFORM}/${ARCH}/${NAME}
	$Qecho Done!

$(OBJ_PATH)/$(PLATFORM)/$(ARCH)/%.o: %.cpp
	$Qecho Making $<...
	$Q${CC} -c $< ${FLAGS} ${INCLUDE} -o $@ 
	$Q${CC} -MM -MF $(@:.o=.d) -MT $@ $< ${FLAGS} ${INCLUDE}

clean:
	$Q$(RM_CMD) ${OBJ_PATH}/*

run: 
	$Q${OUT_PATH}/${PLATFORM}/${ARCH}/${NAME} 2

help:
	$Qecho "Usage: make [TARGET] [PLATFORM=<platform>] [ARCH=<architecture>]"
	$Qecho "Targets:"
	$Qecho "	help	- Shows this message."
	$Qecho "	build	- Builts the project. Default PLATFORM=linux, ARCH=x64."
	$Qecho "		Example: make build PLATFORM=windows ARCH=x64"
	$Qecho "	run	- Run the built binary. Default PLATFORM=linux, ARCH=x64."
	$Qecho "		Example: make run PLATFORM=windows"
	$Qecho "	clean	- Cleans all the object files."
	$Qecho "	all     - Builts the project for all supported platforms and architectures."

SUPPORTED_PLATFORMS = linux windows
SUPPORTED_ARCHS = x64
all:
	for platform in $(SUPPORTED_PLATFORMS); do \
        for arch in $(SUPPORTED_ARCHS); do \
            $(MAKE) build PLATFORM=$$platform ARCH=$$arch; \
        done; \
    done
