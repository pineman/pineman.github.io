#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  make
}

watch() {
  export NOFORMAT=
  ls posts/*.md *.erb build.rb | \
    entr -s 'echo "Detected change in: $0"; \
      case "$0" in \
        *.md) \
          basename=$(basename "$0" .md); \
          ./build.rb "$basename.html" \
          ;; \
        *) \
          make \
          ;; \
      esac' | \
    ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
