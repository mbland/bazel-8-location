TARGET = "@org_apache_commons_commons_lang3_3_5"
VARS = [
    "execpath",
    "rootpath",
    "location",
]
EXPANSIONS = [
    "\"{v}: $({v} {t})\"".format(v = var, t = TARGET) for var in VARS
]

genrule(
    name = "build-expansions",
    srcs = [TARGET],
    outs = ["build-expansions.txt"],
    cmd = "\n".join(["echo %s >>$@" % e for e in EXPANSIONS])
)

sh_binary(
    name = "run-expansions",
    srcs = ["show-expansions.sh"],
    data = [
        ":build-expansions",
        TARGET,
    ],
    args = [ "$(rootpath :build-expansions)" ] + EXPANSIONS,
)
