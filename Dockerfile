FROM alpine:3.19

RUN apk add --no-cache \
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
    luajit-dev \
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

# Install Fennel
RUN curl -L https://fennel-lang.org/downloads/fennel-1.4.0 -o /usr/bin/fennel && \
    chmod +x /usr/bin/fennel

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
    meson setup build -Ddefault_library=static -Dexamples=disabled -Dtests=disabled && \
    ninja -C build install && \
    rm -rf /tmp/libnice

# Build libdatachannel
RUN git clone --recursive https://github.com/paullouisageneau/libdatachannel.git /tmp/libdatachannel && \
    cd /tmp/libdatachannel && \
    cmake -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DUSE_NICE=ON \
        -DNO_WEBSOCKET=OFF \
        -DNO_MEDIA=ON && \
    cmake --build build --target install && \
    rm -rf /tmp/libdatachannel

WORKDIR /work
