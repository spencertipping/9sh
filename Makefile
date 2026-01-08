# OS Detection
OS_NAME      := $(shell uname -s)

# Global Settings
CXX          := g++
CXXFLAGS     := -std=c++23 -Os -ffunction-sections -fdata-sections -Isrc -I/usr/include/luajit-2.1
LDFLAGS      :=

# Linux Configuration
# Linux Configuration
ifeq ($(OS_NAME),Linux)
CXXFLAGS     += -I/usr/local/include -I/usr/include
LDFLAGS      += -Wl,--export-dynamic -L/usr/local/lib -L/usr/lib \
                -L/usr/lib/x86_64-linux-gnu -L/usr/lib/aarch64-linux-gnu

# Use pkg-config to handle distro differences (e.g. -ltinfo on Ubuntu vs ncursesw on Alpine)
PKG_WHOLE    := readline sqlite3 vterm
PKG_STD      := nice glib-2.0 gthread-2.0 openssl

LIBS_WHOLE   := $(filter-out -lm,$(shell pkg-config --libs --static $(PKG_WHOLE)))
LIBS_STD     := $(filter-out -lm,$(shell pkg-config --libs --static $(PKG_STD)))

# Force static linking for core dependencies
# We use -Wl,-Bstatic to force static linking for the libraries found,
# and switch back to -Wl,-Bdynamic for system libraries (pthread, dl).
LIBS         := -Wl,-Bstatic -Wl,--whole-archive $(LIBS_WHOLE) -Wl,--no-whole-archive \
                $(LIBS_STD) -lluajit-5.1 -ldatachannel -lboost_system \
                -Wl,-Bdynamic -lpthread -ldl -lm
endif

# MacOS Configuration
ifeq ($(OS_NAME),Darwin)
# Assume Homebrew paths for dependencies.
BREW_PREFIX  := $(shell brew --prefix)
CXXFLAGS     += -I$(BREW_PREFIX)/include -I$(BREW_PREFIX)/opt/readline/include \
                -I$(BREW_PREFIX)/opt/openssl@3/include \
                -I$(BREW_PREFIX)/include/luajit-2.1 \
                -I/usr/local/include
LDFLAGS      += -L$(BREW_PREFIX)/lib -L$(BREW_PREFIX)/opt/readline/lib \
                -L$(BREW_PREFIX)/opt/openssl@3/lib \
                -L/usr/local/lib

# Note: We link directly against .a files to ensure static linking
# where possible, avoiding "library not loaded" errors.
# System libs (ncurses, pthread, dl) remain dynamic.
LIBS         := /usr/local/lib/libluajit-5.1.a \
                $(BREW_PREFIX)/opt/readline/lib/libreadline.a \
                $(BREW_PREFIX)/opt/sqlite/lib/libsqlite3.a \
                $(BREW_PREFIX)/opt/openssl@3/lib/libssl.a \
                $(BREW_PREFIX)/opt/openssl@3/lib/libcrypto.a \
                /usr/local/lib/libvterm.a \
                -lncurses -ldatachannel -lpthread -ldl
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
	./9sh tests/core/oop_operators.fnl && \
	make test_linking

test_linking: 9sh
	./scripts/verify_linking.sh ./9sh

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
	sed '1d' $@ > $@.tmp && mv $@.tmp $@
	sed 's/fennel = require("fennel")/fennel = require("fennel"); do return fennel end --/' $@ > $@.tmp && mv $@.tmp $@

clean:
	rm -f 9sh src/*.o src/*.bc src/*.lua src/fennel.lua src/*_bc.cc src/*_bc.h

