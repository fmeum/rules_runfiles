#!/usr/bin/env bash

set -Eeuo pipefail

# C++ & Java
find -name '*.cpp' -o -name '*.h' -o -name '*.java' | xargs clang-format-13 -i

test --noincompatible_strict_action_env

# BUILD files
# go get github.com/bazelbuild/buildtools/buildifier
buildifier -r .

# Licence headers
# go get -u github.com/google/addlicense
addlicense -c "Fabian Meumertzheim" bzlmod/ runfiles/ tests/
