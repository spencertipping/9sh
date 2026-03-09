#!/bin/sh
set -e

exe=${1:-./9sh}
sys=$(uname -s)
err=0

[ -f "$exe" ] || { echo "$exe missing"; exit 1; }

echo "verify $exe [$sys]..."

if [ "$sys" = "Darwin" ]; then
  out=$(otool -L "$exe"); echo "$out"
  echo "$out" | grep -qE "\s/usr/local/lib"     && err=1
  echo "$out" | grep -qE "\s/opt/homebrew"      && err=1
  echo "$out" | grep -qE "\s/usr/local/Cellar"  && err=1

elif [ "$sys" = "Linux" ]; then
  # Due to the inclusion of `dlopen`, Linux binaries are still exported as ELF dynamic
  # executables natively linked to the dynamic musl libc.
  out=$(ldd "$exe" 2>&1 || true)
  echo "$out"
  
  # Anything outside the standard Alpine runtime glibc base (libstdc++, libgcc_s, libc, ld) triggers a failure 
  echo "$out" | grep -vE "lib(stdc\+\+|gcc_s|c)(\.musl-x86_64)?\.so" | grep -vE "^.*/lib/ld-musl-x86_64\.so" | grep -qE "=>" && err=1
fi

[ $err -eq 1 ] && { echo "FAIL: dynamic link detected"; exit 1; }
echo "PASS"
