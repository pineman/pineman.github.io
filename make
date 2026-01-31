#!/usr/bin/env bash


build() {
  rake
  echo "file://$(pwd)/docs/index.html"
}

watch() {
  echo "file://$(pwd)/docs/index.html"
  export NOFORMAT=
  ls posts/*.md notes/*.md templates/* Rakefile | \
    entr -s 'echo "Detected change in: $0"; rake' | \
    ts '[%Y-%m-%d %H:%M:%S]'
}

serve() {
  ruby -run -e httpd docs/
}

eval "${@:-build}"
