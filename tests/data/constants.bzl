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

COMMON_DATA = [
    "//data/foo:a.txt",
    "//data/foo:bar",
    "//data/foo:bar/b.txt",
    "@//:BUILD.bazel",
    "@custom_module_name//data/foo:a.txt",
    "@custom_module_name//data/foo:bar",
    "@custom_module_name//data/foo:bar/b.txt",
    "@custom_repo_name//data/foo:a.txt",
    "@custom_repo_name//data/foo:bar",
    "@custom_repo_name//data/foo:bar/b.txt",
]
