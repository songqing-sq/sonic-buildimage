def _pi_python_install_tree_impl(ctx):
    by_destination = {}
    for target in ctx.attr.srcs:
        for src in target.files.to_list():
            if not (src.basename.endswith(".py") or src.basename.endswith(".pyi")):
                continue
            path = src.short_path
            destination = None
            if "p4lang_pi_src/" in path:
                path = path.split("p4lang_pi_src/", 1)[1]
                if path.startswith("proto/"):
                    destination = path[len("proto/"):]
            elif "pi_googleapis/" in path:
                path = path.split("pi_googleapis/", 1)[1]
                marker = "/google/"
                if marker in path:
                    destination = "google/" + path.split(marker, 1)[1]
            elif "pi_p4runtime/" in path:
                path = path.split("pi_p4runtime/", 1)[1]
                if path.startswith("p4/"):
                    destination = path
            if destination != None:
                by_destination[destination] = src

    outputs = []
    for destination in sorted(by_destination.keys()):
        output = ctx.actions.declare_file("pi_python/" + destination)
        ctx.actions.symlink(output = output, target_file = by_destination[destination])
        outputs.append(output)
    return [DefaultInfo(files = depset(outputs))]

pi_python_install_tree = rule(
    implementation = _pi_python_install_tree_impl,
    attrs = {"srcs": attr.label_list()},
)
