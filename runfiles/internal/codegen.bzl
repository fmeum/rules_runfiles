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

load(":common.bzl", "escape")

def generate_nested_structure(runfile_structs, begin_group, end_group, emit, indent_per_level = 0):
    runfiles_per_path = {}
    for runfile in runfile_structs:
        segments = [runfile.repo] + (runfile.pkg.split("/") if runfile.pkg else [])
        segments = [escape(s) for s in segments]
        segments = tuple(segments)
        runfiles_per_path.setdefault(segments, []).append(runfile)

    paths = sorted(runfiles_per_path.keys())

    # Sentinel values to close the last group.
    paths.append(tuple())
    runfiles_per_path[tuple()] = []

    # Sentinel value to open the first group.
    previous_segments = []
    code = []
    for segments in paths:
        mismatch_pos = _mismatch(previous_segments, segments)
        if mismatch_pos != -1:
            for pos in range(len(previous_segments) - 1, mismatch_pos - 1, -1):
                code.append(_indent(end_group(previous_segments[pos]), indent_per_level * pos))
            for pos in range(mismatch_pos, len(segments)):
                code.append(_indent(begin_group(segments[pos]), indent_per_level * pos))
        definitions = []
        for runfile in runfiles_per_path[segments]:
            definitions.append(_indent(emit(runfile), indent_per_level * len(segments)))
        if definitions:
            code.append("\n\n".join(definitions))
        previous_segments = segments

    return "\n".join(code)

def _mismatch(l1, l2):
    min_length = min(len(l1), len(l2))
    for i in range(min_length):
        if l1[i] != l2[i]:
            return i
    if len(l1) == len(l2):
        return -1
    else:
        return min_length

def _indent(s, level):
    if level == 0:
        return s
    indent = level * " "
    return "\n".join([indent + line for line in s.split("\n")])
