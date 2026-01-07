# OS Detection
OS_NAME      := $(shell uname -s)

# Global Settings
CXX          := g++
CXXFLAGS     := -std=c++23 -Os -ffunction-sections -fdata-sections -Isrc -I/usr/include/luajit-2.1
LDFLAGS      :=

# Linux Configuration
ifeq ($(OS_NAME),Linux)
CXXFLAGS     += -static -I/usr/local/include -I/usr/include
LDFLAGS      += -static -Wl,--export-dynamic -L/usr/local/lib -L/usr/lib \
                -L/usr/lib/x86_64-linux-gnu -L/usr/lib/aarch64-linux-gnu

# Use pkg-config to handle distro differences (e.g. -ltinfo on Ubuntu vs ncursesw on Alpine)
PKG_WHOLE    := readline sqlite3 vterm
PKG_STD      := luajit nice glib-2.0 gthread-2.0 openssl

LIBS_WHOLE   := $(shell pkg-config --libs --static $(PKG_WHOLE))
LIBS_STD     := $(shell pkg-config --libs --static $(PKG_STD))

LIBS         := -Wl,--whole-archive $(LIBS_WHOLE) -Wl,--no-whole-archive \
                $(LIBS_STD) -ldatachannel -lboost_system -lpthread -ldl
endif

# MacOS Configuration
ifeq ($(OS_NAME),Darwin)
# Assume Homebrew paths for dependencies.
# Note: Linking statically on macOS is discouraged/hard for system libs.
# We modify flags to link dynamically where necessary.
BREW_PREFIX  := $(shell brew --prefix)
CXXFLAGS     += -I$(BREW_PREFIX)/include -I$(BREW_PREFIX)/opt/readline/include \
                -I$(BREW_PREFIX)/opt/openssl@3/include \
                -I$(BREW_PREFIX)/include/luajit-2.1 \
                -I/usr/local/include
LDFLAGS      += -L$(BREW_PREFIX)/lib -L$(BREW_PREFIX)/opt/readline/lib \
                -L$(BREW_PREFIX)/opt/openssl@3/lib \
                -L/usr/local/lib
LIBS         := -lluajit-5.1 -lreadline -lncurses -lsqlite3 -lvterm \
                -ldatachannel -lboost_system -lpthread -ldl -lssl -lcrypto
endif

# Fennel Source Management
FNL_SRCS     := $(wildcard src/*.fnl)
LUA_GEN      := $(FNL_SRCS:.fnl=.lua) src/fennel.lua
BC_GEN       := $(LUA_GEN:.lua=.bc)
BC_CC        := $(BC_GEN:.bc=_bc.cc)
BC_HDRS      := $(BC_GEN:.bc=_bc.h)

# C++ Sources
SRCS         := src/main.cc src/bindings.cc src/args.cc src/lua.cc \
                src/bindings/fs.cc src/bindings/asio.cc $(BC_CC)
OBJS         := $(SRCS:.cc=.o)

.PHONY:      all clean debug_vars test

all:         9sh

debug_vars:
	@echo "OS_NAME:  $(OS_NAME)"
	@echo "FNL_SRCS: $(FNL_SRCS)"
	@echo "LUA_GEN:  $(LUA_GEN)"
	@echo "BC_GEN:   $(BC_GEN)"
	@echo "BC_CC:    $(BC_CC)"
	@echo "BC_HDRS:  $(BC_HDRS)"

9sh:         $(OBJS) $(BC_HDRS)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(LDFLAGS) $(LIBS)

# Test Suite
test:        9sh
	export FENNEL_PATH='src/?.fnl;src/?/init.fnl' && \
	export FENNEL_MACRO_PATH='src/?.fnl;src/?/init.fnl' && \
	echo "Running tests..." && \
	./9sh tests/core/fp.fnl && \
	./9sh tests/core/stats.fnl && \
	./9sh tests/core/oop_operators.fnl

# Compilation Rules
%.o:         %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Dependencies
src/main.o:      $(BC_HDRS)
src/bindings.o:  $(BC_HDRS)
src/lua.o:       $(BC_HDRS)

# Fennel Pipeline
src/%.lua:   src/%.fnl
	fennel --compile $< > $@

$(BC_GEN):   src/%.bc: src/%.lua
	luajit -b $< $@

$(BC_CC):    src/%_bc.cc: src/%.bc
	xxd -i $< > $@

$(BC_HDRS):  src/%_bc.h: src/%.bc
	@echo "#pragma once" > $@
	@echo "extern unsigned char $(subst /,_,$(subst .,_,$(<:.bc=_bc)))[];" >> $@
	@echo "extern unsigned int $(subst /,_,$(subst .,_,$(<:.bc=_bc)))_len;" >> $@

src/fennel.lua:
	cp $(shell which fennel) $@
	sed -i '1d' $@
	sed -i 's/assert(arg, "Using the launcher from non-CLI context; use fennel.lua instead.")/if not arg then return require("fennel") end/' $@

clean:
	rm -f 9sh src/*.o src/*.bc src/*.lua src/fennel.lua src/*_bc.cc src/*_bc.h

