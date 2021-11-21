def rlocation_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]
    else:
        return "%s/%s" % (ctx.workspace_name, file.short_path)
