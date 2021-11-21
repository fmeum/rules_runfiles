def merge_runfiles(ctx, targets):
    runfiles = ctx.runfiles()
    for t in targets:
        runfiles = runfiles.merge(ctx.runfiles(transitive_files = t[DefaultInfo].files))
        runfiles = runfiles.merge(t[DefaultInfo].default_runfiles)

    return DefaultInfo(
        runfiles = runfiles,
    )

def escape(s):
    escaped = "".join([_escape_char(c) for c in s.elems()])
    if not escaped or escaped[0].isdigit():
        return "_" + escaped
    return escaped

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

def _stringify_label(label_struct):
    return "@{repo}//{pkg}:{name}".format(
        repo = label_struct.repo,
        pkg = label_struct.pkg,
        name = label_struct.name,
    )