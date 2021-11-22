load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(":common.bzl", "runfile_struct", "merge_runfiles", "escape")

DEFINITION_TEMPLATE = """
{open_namespaces}
/*
 * Target: {target}
 * Label : {raw_label}
 */
const char* {escaped_name} = "{rlocation_path}";
{close_namespaces}
"""

HEADER_TEMPLATE = """// Automatically generated by rules_runfiles.
#ifndef RULES_RUNFILES_{uid}_H_
#define RULES_RUNFILES_{uid}_H_

namespace runfile {{
{content}
}}  // runfile

#endif
"""

def _uid_from_label(label):
    return str(hash(str(label))).replace("-", "M")

def _namespace_for_runfile(runfile):
    return [runfile.repo] + runfile.pkg.split("/")

def _cc_runfiles_impl(ctx):
    runfiles = []
    for i in range(len(ctx.attr.data)):
        target = ctx.attr.data[i]
        raw_label = ctx.attr.raw_labels[i]
        runfiles.append(runfile_struct(ctx, target, raw_label))

    definitions = [
        DEFINITION_TEMPLATE.format(
            open_namespaces = "\n".join(["namespace %s {" % namespace for namespace in _namespace_for_runfile(runfile)]),
            close_namespaces = "\n".join(["} // %s" % namespace for namespace in _namespace_for_runfile(runfile)]),
            escaped_name = escape(runfile.name),
            raw_label = runfile.raw_label,
            rlocation_path = runfile.rlocation_path,
            target = runfile.target,
        )
        for runfile in runfiles
    ]

    header_name = "%s.h" % ctx.attr.name
    header = ctx.actions.declare_file(header_name)
    ctx.actions.write(header, HEADER_TEMPLATE.format(
        content = "".join(definitions),
        uid = _uid_from_label(ctx.label),
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
    runfiles_header_and_lib_cc_info = cc_common.merge_cc_infos(
        direct_cc_infos = [
            CcInfo(compilation_context = compilation_context),
            ctx.attr._runfiles_lib[CcInfo],
        ],
    )

    return [
        merge_runfiles(ctx, ctx.attr.data),
        runfiles_header_and_lib_cc_info,
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
        "_runfiles_lib": attr.label(default = "@bazel_tools//tools/cpp/runfiles"),
    },
    fragments = ["cpp"],
    incompatible_use_toolchain_transition = True,
    provides = [CcInfo],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)

def cc_runfiles(name, data, **kwargs):
    _cc_runfiles(
        name = name,
        data = data,
        raw_labels = data,
        *kwargs,
    )
