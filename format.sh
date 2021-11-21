# C++ & Java
find -name '*.c' \
     -o -name '*.cpp' \
     -o -name '*.h' \
     -o -name '*.java' \
  | xargs clang-format-12 -i

# BUILD files
# go get github.com/bazelbuild/buildtools/buildifier
buildifier -r .

# Licence headers
# go get -u github.com/google/addlicense
addlicense -c "Fabian Meumertzheim" runfiles/ tests/
