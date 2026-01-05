#!/usr/bin/env bash


build() {
  rake -s
  echo "file://$(pwd)/index.html"
}

watch() {
  echo "file://$(pwd)/index.html"
  export NOFORMAT=
  ls posts/*.md templates/* Rakefile | \
    entr -s 'echo "Detected change in: $0"; \
      case "$0" in \
        *.md) \
          rake "$(basename "$0" .md).html" \
          ;; \
        *) \
          rake \
          ;; \
      esac' | \
    ts '[%Y-%m-%d %H:%M:%S]'
}

serve() {
  ruby -run -e httpd
}

eval "${@:-build}"
