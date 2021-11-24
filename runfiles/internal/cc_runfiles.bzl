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

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(":common.bzl", "escape", "merge_runfiles", "runfile_structs")

DEFINITION_TEMPLATE = """
{open_namespaces}
/*
 * Original label: {raw_label}
 * Remapped label: {remapped_label}
 */
const char* {escaped_name} = "{rlocation_path}";
{close_namespaces}
"""

HEADER_TEMPLATE = """// Automatically generated by rules_runfiles.
#ifndef RULES_RUNFILES_{uid}_H_
#define RULES_RUNFILES_{uid}_H_

namespace runfiles {{
{content}
}}  // runfiles

#endif
"""

def _cc_runfiles_impl(ctx):
    runfiles = runfile_structs(ctx, ctx.attr.data, ctx.attr.raw_labels)

    definitions = [
        DEFINITION_TEMPLATE.format(
            open_namespaces = "\n".join(["namespace %s {" % namespace for namespace in _namespace_segments(runfile)]),
            close_namespaces = "\n".join(["} // %s" % namespace for namespace in _namespace_segments(runfile)]),
            escaped_name = escape(runfile.name),
            raw_label = runfile.raw_label,
            remapped_label = runfile.remapped_label,
            rlocation_path = runfile.rlocation_path,
        )
        for runfile in runfiles
    ]

    header_name = "%s.h" % ctx.attr.name
    header = ctx.actions.declare_file(header_name)
    ctx.actions.write(header, HEADER_TEMPLATE.format(
        content = "".join(definitions),
        uid = _label_uid(ctx.label),
    ))

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    compilation_context, _ = cc_common.compile(
        name = ctx.attr.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        public_hdrs = [header],
    )

    return [
        merge_runfiles(ctx, ctx.attr.data),
        CcInfo(compilation_context = compilation_context),
    ]

_cc_runfiles = rule(
    implementation = _cc_runfiles_impl,
    attrs = {
        "data": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "raw_labels": attr.string_list(),
        "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
    },
    fragments = ["cpp"],
    provides = [CcInfo],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

def cc_runfiles(name, data, **kwargs):
    _cc_runfiles(
        name = name,
        data = data,
        raw_labels = data,
        *kwargs
    )

def _label_uid(label):
    return str(hash(str(label))).replace("-", "M")

def _namespace_segments(runfile):
    return [runfile.repo] + runfile.pkg.split("/")
