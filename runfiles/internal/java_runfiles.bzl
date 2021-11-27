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

load("@bazel_tools//tools/jdk:toolchain_utils.bzl", "find_java_toolchain")
load(":common.bzl", "camel_case_identifier", "escape", "make_default_info", "runfile_structs")

DEFINITION_TEMPLATE = """
  /*
   * Original label: {raw_label}
   * Remapped label: {remapped_label}
   */
  public static final String {escaped_full_label_path} = "{rlocation_path}";
"""

CLASS_TEMPLATE = """// Automatically generated by rules_runfiles.
package {package};

public final class {class_name} {{
{content}
}}
"""

def _java_runfiles_impl(ctx):
    runfiles = runfile_structs(ctx, ctx.attr.data, ctx.attr.raw_labels)

    definitions = [
        DEFINITION_TEMPLATE.format(
            escaped_full_label_path = escape(_full_label_path(runfile)).upper(),
            raw_label = runfile.raw_label,
            remapped_label = runfile.remapped_label,
            rlocation_path = runfile.rlocation_path,
        )
        for runfile in runfiles
    ]

    class_name = camel_case_identifier(ctx.attr.name)
    java_file_name = "%s.java" % class_name
    java_file = ctx.actions.declare_file(java_file_name)
    java_package = _get_java_full_classname(ctx.label.package)
    ctx.actions.write(java_file, CLASS_TEMPLATE.format(
        class_name = class_name,
        content = "".join(definitions),
        package = java_package,
    ))

    jar_file_name = "%s.jar" % class_name
    jar_file = ctx.actions.declare_file(jar_file_name)

    java_toolchain = find_java_toolchain(ctx, ctx.attr._java_toolchain)
    java_info = java_common.compile(
        ctx,
        java_toolchain = java_toolchain,
        output = jar_file,
        source_files = [java_file],
    )

    return [
        make_default_info(ctx, ctx.attr.data),
        java_common.merge([
            java_info,
            ctx.attr._runfiles_lib[JavaInfo],
        ]),
    ]

_java_runfiles = rule(
    implementation = _java_runfiles_impl,
    attrs = {
        "data": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "raw_labels": attr.string_list(),
        "_java_toolchain": attr.label(default = "@bazel_tools//tools/jdk:current_java_toolchain"),
        "_runfiles_lib": attr.label(default = "//third_party/bazel_tools/tools/java/runfiles"),
    },
    fragments = ["java"],
    provides = [JavaInfo],
)

def java_runfiles(name, data, **kwargs):
    _java_runfiles(
        name = name,
        data = data,
        raw_labels = data,
        **kwargs
    )

def _full_label_path(runfile):
    segments = [runfile.repo] + runfile.pkg.split("/") + [runfile.name]
    return "/".join([segment for segment in segments if segment])

# A slightly modified Starlark reimplementation of Bazel's JavaUtil#getJavaFullClassname.
def _get_java_full_classname(source_pkg):
    java_path = _get_java_path(source_pkg)
    if java_path != None:
        return java_path.replace("/", ".")
    return source_pkg

# A Starlark reimplementation of Bazel's JavaUtil#getJavaPath.
def _get_java_path(main_source_path):
    path_segments = main_source_path.split("/")
    index = _java_segment_index(path_segments)
    if index >= 0:
        return "/".join(path_segments[index + 1:])
    return None

_KNOWN_SOURCE_ROOTS = ["java", "javatests", "src", "testsrc"]

# A Starlark reimplementation of Bazel's JavaUtil#javaSegmentIndex.
def _java_segment_index(path_segments):
    root_index = -1
    for pos, segment in enumerate(path_segments):
        if segment in _KNOWN_SOURCE_ROOTS:
            root_index = pos
            break
    if root_index == -1:
        return root_index

    is_src = "src" == path_segments[root_index]
    check_maven_index = root_index if is_src else -1
    max = len(path_segments) - 1
    if root_index == 0 or is_src:
        for i in range(root_index + 1, max):
            segment = path_segments[i]
            if "src" == segment or (is_src and ("javatests" == segment or "java" == segment)):
                next = path_segments[i + 1]
                if ("com" == next or "org" == next or "net" == next):
                    root_index = i
                elif "src" == segment:
                    check_maven_index = i
                break

    if check_maven_index >= 0 and check_maven_index + 2 < len(path_segments):
        next = path_segments[check_maven_index + 1]
        if "main" == next or "test" == next:
            next = path_segments[check_maven_index + 2]
            if "java" == next or "resources" == next:
                root_index = check_maven_index + 2

    return root_index
