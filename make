#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  cd src
  npm ci
  bundle
  ./build.rb
}

watch() {
  cd src
  ls ../posts/*.md *.erb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
