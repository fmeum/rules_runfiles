# Copyright 2021 Fabian Meumertzheim
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
