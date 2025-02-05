BUILD_FILE_TEMPLATE = """
java_import(
   name = "{name}",
   jars = ["{path}"],
   visibility = ["//visibility:public"],
)
"""

def _repro_repository_impl(rctx):
    url = rctx.attr.url
    path = url[url.rindex("/") + 1:]
    build_file_content =  BUILD_FILE_TEMPLATE.format(
        name = rctx.attr.generated_name,
        path = path,
    )

    rctx.download([url], path, rctx.attr.sha256)
    rctx.file("BUILD", build_file_content)

repro_repository = repository_rule(
    implementation = _repro_repository_impl,
    attrs = {
        "generated_name": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
)
