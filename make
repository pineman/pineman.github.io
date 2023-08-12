#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  cd lib
  ./build.rb
}

watch() {
  cd lib
  ls ../posts/*.md *.erb build.rb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
