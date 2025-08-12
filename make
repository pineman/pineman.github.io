#!/usr/bin/env bash

echo "file://$(pwd)/index.html"

build() {
  rake
}

watch() {
  export NOFORMAT=
  ls posts/*.md *.erb Rakefile | \
    entr -s 'echo "Detected change in: $0"; \
      case "$0" in \
        *.md) \
          basename=$(basename "$0" .md); \
          rake "$basename.html" \
          ;; \
        *) \
          rake \
          ;; \
      esac' | \
    ts '[%Y-%m-%d %H:%M:%S]'
}

eval "${@:-build}"
