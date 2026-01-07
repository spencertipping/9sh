#!/bin/sh
set -e


# ------------------------------------------------------------------------------
# setup
# ------------------------------------------------------------------------------

os=$(uname -s)
dist=""
su=""

if [ -f /etc/os-release ]; then
  . /etc/os-release
  dist=$ID
fi

if [ "$(id -u)" -ne 0 ]; then
  su="sudo"
fi

echo "os=$os dist=$dist"


# ------------------------------------------------------------------------------
# helpers
# ------------------------------------------------------------------------------

install_sys_deps()
{
  echo "installing sys deps..."

  if [ "$dist" = "alpine" ]; then
    apk add --no-cache                                                         \
      bash build-base cmake git linux-headers perl samurai                     \
      openssl-dev openssl-libs-static                                          \
      readline-dev readline-static                                             \
      sqlite-dev sqlite-static                                                 \
      boost-dev boost-static                                                   \
      curl libtool automake autoconf                                           \
      glib-dev glib-static meson ncurses-static pkgconf                        \
      zlib-static util-linux-dev util-linux-static

  elif [ "$dist" = "ubuntu" ] || [ "$dist" = "debian" ] || [ "$os" = "Linux" ]; then
    $su apt-get update
    $su apt-get install -y                                                     \
      build-essential cmake git ninja-build meson curl                         \
      libreadline-dev libncurses-dev libsqlite3-dev libssl-dev                 \
      libboost-system-dev libglib2.0-dev libtool libtool-bin                   \
      automake autoconf pkg-config xxd                                         \
      zlib1g-dev libblkid-dev libmount-dev

  elif [ "$os" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      brew update
      brew install                                                             \
        cmake ninja readline sqlite boost openssl@3                            \
        glib libvterm libnice
    else
      echo "brew not found; skipping sys deps"
    fi
  fi
}


build_luajit()
{
  echo "building luajit..."

  tmp=$(mktemp -d)
  git clone https://github.com/LuaJIT/LuaJIT.git "$tmp/luajit"

  cd "$tmp/luajit"

  if [ "$os" = "Darwin" ]; then
    export MACOSX_DEPLOYMENT_TARGET=12.0
  fi

  make XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT
  $su make install

  if [ "$dist" = "alpine" ]; then
    ln -sf /usr/local/bin/luajit /usr/bin/luajit
  fi

  rm -rf "$tmp"
  cd -
}


build_libvterm()
{
  echo "building libvterm..."

  tmp=$(mktemp -d)
  git clone https://github.com/neovim/libvterm.git "$tmp/libvterm"

  cd "$tmp/libvterm"
  make
  $su make install

  rm -rf "$tmp"
  cd -
}


build_libnice()
{
  echo "building libnice..."

  tmp=$(mktemp -d)
  git clone https://gitlab.freedesktop.org/libnice/libnice.git "$tmp/libnice"

  cd "$tmp/libnice"
  meson setup build                                                            \
    -Ddefault_library=static                                                   \
    -Dexamples=disabled                                                        \
    -Dtests=disabled                                                           \
    --prefix=/usr/local

  $su ninja -C build install

  rm -rf "$tmp"
  cd -
}


build_libdatachannel()
{
  echo "building libdatachannel..."

  tmp=$(mktemp -d)
  git clone --recursive https://github.com/paullouisageneau/libdatachannel.git "$tmp/libdatachannel"

  cd "$tmp/libdatachannel"

  pfx="/usr/local"
  if [ "$os" = "Darwin" ]; then
    b_pfx=$(brew --prefix 2>/dev/null || echo /usr)
    pfx="/usr/local;$b_pfx"
  fi

  cmake -B build -G Ninja                                                      \
    -DCMAKE_BUILD_TYPE=MinSizeRel                                              \
    -DBUILD_SHARED_LIBS=OFF                                                    \
    -DUSE_NICE=ON                                                              \
    -DNO_WEBSOCKET=OFF                                                         \
    -DNO_MEDIA=ON                                                              \
    -DNO_EXAMPLES=ON                                                           \
    -DNO_TESTS=ON                                                              \
    -DCMAKE_PREFIX_PATH="$pfx"

  $su cmake --build build --target install

  rm -rf "$tmp"
  cd -
}


install_fennel()
{
  echo "installing fennel..."

  curl -L https://fennel-lang.org/downloads/fennel-1.4.0 -o fennel
  chmod +x fennel
  $su mv fennel /usr/local/bin/fennel

  if [ "$dist" = "alpine" ]; then
    ln -sf /usr/bin/luajit /usr/bin/lua
  else
    $su ln -sf /usr/local/bin/luajit /usr/local/bin/lua
  fi
}


# ------------------------------------------------------------------------------
# main
# ------------------------------------------------------------------------------

install_sys_deps
build_luajit

if [ "$os" = "Linux" ]; then
  build_libvterm
  build_libnice
  build_libdatachannel

elif [ "$os" = "Darwin" ]; then
  build_libdatachannel
fi

install_fennel
echo "deps installed successfully"
