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

load(":rlocation_path.bzl", "rlocation_path")

NO_FILES_MESSAGE = """target '{raw_label}' does not provide any files"""

MORE_THAN_ONE_FILE_MESSAGE = """target '{raw_label}' provides more than one file:

  {files}

Either use an existing more fine-grained target or use a rule such as
bazel-skylib's select_file to extract a single file from this target.
"""

def escape(s):
    escaped = "".join([_escape_char(c) for c in s.elems()])
    if not escaped or escaped[0].isdigit():
        return "_" + escaped
    return escaped

def merge_runfiles(ctx, targets):
    runfiles = ctx.runfiles()
    for t in targets:
        runfiles = runfiles.merge(ctx.runfiles(transitive_files = t[DefaultInfo].files))
        runfiles = runfiles.merge(t[DefaultInfo].default_runfiles)

    return DefaultInfo(
        runfiles = runfiles,
    )

def parse_label(label, current_repo, current_pkg):
    if label.startswith("@"):
        repo_end = label.find("//")
        if repo_end != -1:
            repo = label[len("@"):repo_end]
            remainder = label[repo_end:]
        else:
            repo = label[len("@"):]
            remainder = "//:" + repo
    else:
        repo = current_repo
        remainder = label

    pkg, name = _parse_same_repo_label(remainder, current_pkg)
    return struct(
        repo = repo,
        pkg = pkg,
        name = name,
    )

def runfile_structs(ctx, targets, raw_labels):
    return [_runfile_struct(ctx, target, raw_label) for target, raw_label in zip(targets, raw_labels)]

def _runfile_struct(ctx, target, raw_label):
    files = target[DefaultInfo].files.to_list()
    if len(files) == 0:
        fail(NO_FILES_MESSAGE.format(
            raw_label = raw_label,
        ))
    if len(files) > 1:
        fail(MORE_THAN_ONE_FILE_MESSAGE.format(
            raw_label = raw_label,
            files = "\n  ".join([rlocation_path(ctx, file) for file in files]),
        ))
    file = files[0]
    parsed_label = parse_label(raw_label, "current", ctx.label.package)
    return struct(
        name = parsed_label.name,
        pkg = parsed_label.pkg,
        raw_label = raw_label,
        repo = parsed_label.repo if parsed_label.repo else "main",
        rlocation_path = rlocation_path(ctx, file),
        remapped_label = target.label,
    )

def _escape_char(c):
    if c.isalnum():
        return c
    else:
        return "_"

def _parse_same_repo_label(label, current_pkg):
    if label.startswith("//"):
        pkg_end = label.find(":")
        if pkg_end != -1:
            pkg = label[len("//"):pkg_end]
            name = label[pkg_end + len(":"):]
        else:
            pkg = label[len("//"):]
            name = pkg.split("/")[-1]
    else:
        pkg = current_pkg
        name = label.lstrip(":")

    return pkg, name
