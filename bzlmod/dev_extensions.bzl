load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")
load(":local_repository.bzl", "starlarkified_local_repository")

def _install_dev_dependencies(ctx):
    starlarkified_local_repository(
        name = "other_repo",
        path = "tests/data/other_repo",
    )

install_dev_dependencies = module_extension(
    implementation = _install_dev_dependencies,
)
