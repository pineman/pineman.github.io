#!/bin/bash
set -euo pipefail

ROOT=$(pwd)
cd templates
ls * | entr fd '\.erb$' -x sh -c "erb {} > $ROOT/{.}"
