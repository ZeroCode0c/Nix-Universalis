local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local fmt = require("luasnip.extras.fmt").fmt
local types = require("luasnip.util.types")

ls.add_snippets("python", {
  s(
    "cmd",
    fmt(
      [[
subprocess.run("{}", shell={}, check={})
  ]],
      {
        i(1, "ls -l | grep py"),
        c(2, { t("True"), t("False") }),
        c(3, { t("True"), t("False") }),
      }
    )
  ),
})

ls.add_snippets("python", {
  s(
    "bash",
    fmt(
      [[
bash = """
{}
"""

sh(bash)
  ]],
      {
        i(1, "echo 'hola mundo'"),
      }
    )
  ),
})

ls.add_snippets("python", {
  s(
    "sh",
    fmt(
      [[
def sh(bash):
    lines = bash.split("\n")
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        subprocess.run(line, shell=True, check=False)
  ]],
      {}
    )
  ),
})
