#!/usr/bin/env bash


build() {
  bundle exec rake
  echo "file://$(pwd)/docs/index.html"
}

watch() {
  echo "file://$(pwd)/docs/index.html"
  export NOFORMAT=
  ls posts/*.md notes/*.md templates/* Rakefile | \
    entr -s 'echo "Detected change in: $0"; bundle exec rake' | \
    ts '[%Y-%m-%d %H:%M:%S]'
}

clean() {
  bundle exec rake clean
}

remake() {
  bundle exec rake clean
  bundle exec rake
}

serve() {
  ruby -run -e httpd docs/
}

eval "${@:-build}"
