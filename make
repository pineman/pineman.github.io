#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  cd templates
  ./build.rb
}

watch() {
  cd templates
  ls posts/*.md *.erb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
