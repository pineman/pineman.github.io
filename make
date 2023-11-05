#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  cd src
  ./build.rb
  sd -s "<summary>" "<summary type=\"html\">" ../atom.xml
}

watch() {
  cd src
  export NOFORMAT=
  ls ../posts/*.md *.erb build.rb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
