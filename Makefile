CXX := g++
CXXFLAGS := -std=c++17 -O2 -static -I/usr/local/include -I/usr/include
LDFLAGS := -L/usr/local/lib -L/usr/lib -static

# Libraries
LIBS := -lluajit-5.1 -lreadline -lsqlite3 -ldatachannel -lvterm -lboost_system -lpthread -ldl -lssl -lcrypto -lnice -lglib-2.0 -lgthread-2.0 -lintl

# Sources
SRCS := src/main.cc
OBJS := $(SRCS:.cc=.o)
GEN_HDRS := src/boot.h src/fennel.h

.PHONY: all clean

all: 9sh

# Download Fennel
src/fennel.lua:
	curl -L https://fennel-lang.org/downloads/fennel-1.4.0.lua -o $@

# Compile Fennel library to Bytecode
src/fennel.bc: src/fennel.lua
	luajit -b $< $@

# Embed Fennel Bytecode
src/fennel.h: src/fennel.bc
	xxd -i $< > $@

# Compile Fennel boot script to Lua
src/boot.lua: src/boot.fnl
	fennel --compile $< > $@

# Compile Lua to Bytecode
src/boot.bc: src/boot.lua
	luajit -b $< $@

# Embed Bytecode as C header
# xxd -i creates an array named src_boot_bc and length src_boot_bc_len
src/boot.h: src/boot.bc
	xxd -i $< > $@

# Main dependency
src/main.o: src/main.cc $(GEN_HDRS)

9sh: $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS)

clean:
	rm -f 9sh src/*.o src/*.lua src/*.bc src/*.h
