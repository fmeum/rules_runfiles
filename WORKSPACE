workspace(name = "rules_runfiles")

local_repository(
    name = "rules_runfiles_tests",
    path = "tests",
)

local_repository(
    name = "custom_module_name",
    path = "tests/data/other_module",
)

local_repository(
    name = "custom_repo_name",
    path = "tests/data/other_repo",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_skylib",
    sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    urls = [
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
    ],
)

register_toolchains(
    "@bazel_skylib//toolchains/unittest:cmd_toolchain",
    "@bazel_skylib//toolchains/unittest:bash_toolchain",
)
