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
  out=$(ldd "$exe"); echo "$out"
  echo "$out" | grep -qE " => /usr/local/lib"   && err=1
fi

[ $err -eq 1 ] && { echo "FAIL: dynamic link detected"; exit 1; }
echo "PASS"
