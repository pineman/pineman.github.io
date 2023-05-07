#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  cd src
  bundle
  ./build.rb
}

watch() {
  cd src
  ls ../posts/*.md *.erb build.rb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
