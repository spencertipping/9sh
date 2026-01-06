FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    build-base \
    cmake \
    git \
    linux-headers \
    perl \
    samurai \
    openssl-dev \
    openssl-libs-static \
    readline-dev \
    readline-static \
    sqlite-dev \
    sqlite-static \
    boost-dev \
    boost-static \
    curl \
    libtool \
    automake \
    autoconf \
    glib-dev \
    glib-static \
    meson \
    ncurses-static \
    pkgconf

# Build LuaJIT with 5.2 compatibility (for # operator on tables)
RUN git clone https://github.com/LuaJIT/LuaJIT.git /tmp/luajit && \
    cd /tmp/luajit && \
    make XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT && \
    make install && \
    ln -sf /usr/local/bin/luajit /usr/bin/luajit && \
    rm -rf /tmp/luajit

# Install Fennel
RUN curl -L https://fennel-lang.org/downloads/fennel-1.4.0 -o /usr/bin/fennel && \
    chmod +x /usr/bin/fennel && \
    ln -s /usr/bin/luajit /usr/bin/lua

# Build libvterm
RUN git clone https://github.com/neovim/libvterm.git /tmp/libvterm && \
    cd /tmp/libvterm && \
    make && \
    make install && \
    rm -rf /tmp/libvterm

# Build libnice (since apk lacks static lib usually, checking safely)
# Actually, let's try to build libnice from source to be sure we get a static lib.
RUN git clone https://gitlab.freedesktop.org/libnice/libnice.git /tmp/libnice && \
    cd /tmp/libnice && \
    meson setup build -Ddefault_library=static -Dexamples=disabled -Dtests=disabled --prefix=/usr/local && \
    ninja -C build install && \
    rm -rf /tmp/libnice

# Build libdatachannel
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/lib/pkgconfig
RUN git clone --recursive https://github.com/paullouisageneau/libdatachannel.git /tmp/libdatachannel && \
    cd /tmp/libdatachannel && \
    cmake -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DBUILD_SHARED_LIBS=OFF \
        -DUSE_NICE=ON \
        -DNO_WEBSOCKET=OFF \
        -DNO_MEDIA=ON \
        -DNO_EXAMPLES=ON \
        -DNO_TESTS=ON \
        -DCMAKE_PREFIX_PATH=/usr/local && \
    cmake --build build --target install && \
    rm -rf /tmp/libdatachannel

WORKDIR /work
