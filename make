#!/usr/bin/env bash

echo "file://$(pwd)/index.html"
cd templates
ls posts/*.md *.erb | entr -d ./build.rb | ts '[%Y-%m-%d %H:%M:%S]'
