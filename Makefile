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
MKDIR_CMD:=mkdir
RM_CMD:=del /Q /S
FIND_CMD:=for /R
CP_CMD:=copy
else
MKDIR_CMD:=mkdir -p
RM_CMD:=rm -r
FIND_CMD:=find
CP_CMD:=cp
endif

# ===PROGRAM SETUP===
NAME:= Boards

OUT_PATH:= ../bin
OBJ_PATH:= ../obj

MODULES = main debug
SOURCES:= $(shell $(FIND_CMD) $(MODULES) -name "*.cpp")
OBJS = $(SOURCES:%.cpp=$(OBJ_PATH)/$(PLATFORM)/$(ARCH)/%.o)
DEPS = $(OBJS:.o=.d)
-include $(DEPS)

INCLUDE := $(shell $(FIND_CMD) ./include -type d)
INCLUDE := $(INCLUDE:%=-I%)
INCLUDE += -I./ -I/include
LIBS:=
FLAGS:= -Wall \
	   -Wextra \
	   -Wconversion \
	   -Wpedantic \
	   -Wmaybe-uninitialized \
	   -D_NAME=\"$(NAME)\" \
	   -D_DEBUG
	   # -D_RELEASE

setup:
	echo ${OS}
	$Qecho "Making for $(PLATFORM)-$(ARCH)"
	$Q$(MKDIR_CMD) ${OBJ_PATH}/${PLATFORM}/${ARCH}

ifeq ($(OS),Windows_NT)
	for %%M in ($(MODULES)) do ( \
		for /D %%D in (%%M\\*) do ( \
			$(MKDIR_CMD) $(OBJ_PATH)\\$(PLATFORM)\\$(ARCH)\\%%D \
		) \
	)
else
	$Qfor module in $(MODULES); do \
		$(FIND_CMD) $$module -type d | while read subfolder; do \
			$(MKDIR_CMD) ${OBJ_PATH}/${PLATFORM}/${ARCH}/$$subfolder; \
		done; \
	done
endif
	$Q$(MKDIR_CMD) ${OUT_PATH}/${PLATFORM}/${ARCH}

# Platform/Architecture specific setups
linux: $(ARCH)
	$Qecho "Setting up $@ environment..."
	$(eval CC:= g++)
	$Qecho Set compiler as $(CC)...

windows: $(ARCH) 
	$Qecho "Setting up $@ environment..."
	$(eval CC:= x86_64-w64-mingw32-g++)
	$Qecho Set compiler as $(CC)...


build: setup $(PLATFORM) $(OBJS)
	$Qecho Making $(NAME)...
	$Q${CC} ${FLAGS} $(OBJS) ${LIBS} -o ${OUT_PATH}/${PLATFORM}/$(ARCH)/${NAME}
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

#WINDOWS DEFINES
DLLS_PATH=/usr/x86_64-w64-mingw32/bin

DLLS=SDL2 SDL2_image zlib libpng #libjpeg libtiff libwebp
DLLS-WIN=$(LIBS-WIN:%=$(OUT_PATH)/$(WIN_PLATFORM)/%) #LINE WHEN COPYING DLLS

${OUT_PATH}/${WIN_PLATFORM}/%: ${DLLS_PATH}/%*
	@$(CP_CMD) $< ${OUT_PATH}/${WIN_PLATFORM}
