#!/usr/bin/env bash


build() {
  bundle exec rake
  echo "file://$(pwd)/docs/index.html"
}

watch() {
  echo "file://$(pwd)/docs/index.html"
  ls posts/*.md notes/*.md templates/* Rakefile | \
    entr -s 'echo "Detected change in: $0"; bundle exec rake' | \
    ts '[%Y-%m-%d %H:%M:%S]'
}

format() {
  bundle exec rake format
}

clean() {
  bundle exec rake clean
}

remake() {
  bundle exec rake clean default
}

serve() {
  ruby -run -e httpd docs/
}

eval "${@:-build}"
