#!/bin/bash
set -euxo pipefail

rm -rf bundle
cp -r src bundle
npm ci
npx lessc --verbose --source-map-map-inline --clean-css src/style.less bundle/style.css
