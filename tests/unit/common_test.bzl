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

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@fmeum_rules_runfiles//runfiles/internal:common.bzl", "escape", "parse_label")

escape_TESTCASES = {
    "foo": "foo",
    "1.txt": "_1_txt",
    "foo/1.txt": "foo_1_txt",
    "foo/ .txt": "foo___txt",
}

def _escape_test_impl(ctx):
    env = unittest.begin(ctx)
    for string, expected in escape_TESTCASES.items():
        asserts.equals(
            env,
            expected = expected,
            actual = escape(string),
        )
    return unittest.end(env)

escape_test = unittest.make(_escape_test_impl)

_PARSE_LABEL_TESTCASES = {
    "@foo": struct(repo = "foo", pkg = "", name = "foo"),
    "@com_example_foo//file": struct(repo = "com_example_foo", pkg = "file", name = "file"),
    ":test": struct(repo = "repo", pkg = "path/to/pkg", name = "test"),
    "test": struct(repo = "repo", pkg = "path/to/pkg", name = "test"),
    "@foo//:file": struct(repo = "foo", pkg = "", name = "file"),
    "@foo//path:file": struct(repo = "foo", pkg = "path", name = "file"),
    "@foo//path:long/path/to/file.txt": struct(repo = "foo", pkg = "path", name = "long/path/to/file.txt"),
    "@foo//path:!%-@^_` \"#$&'()*-+,;<=>?[]{|}~/.": struct(repo = "foo", pkg = "path", name = "!%-@^_` \"#$&'()*-+,;<=>?[]{|}~/."),
    "@foo//path/path2:file": struct(repo = "foo", pkg = "path/path2", name = "file"),
    "@foo//path/path2": struct(repo = "foo", pkg = "path/path2", name = "path2"),
    "//path/path2": struct(repo = "repo", pkg = "path/path2", name = "path2"),
    "//:name": struct(repo = "repo", pkg = "", name = "name"),
}

def _parse_label_test_impl(ctx):
    env = unittest.begin(ctx)
    for label, expected in _PARSE_LABEL_TESTCASES.items():
        asserts.equals(
            env,
            expected = expected,
            actual = parse_label(label, "repo", "path/to/pkg"),
        )
    return unittest.end(env)

parse_label_test = unittest.make(_parse_label_test_impl)

def common_test_suite(name):
    unittest.suite(
        name,
        escape_test,
        parse_label_test,
    )
