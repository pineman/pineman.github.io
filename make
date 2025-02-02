#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  ./build.rb
}

watch() {
  export NOFORMAT=
  ls ../posts/*.md *.erb build.rb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
