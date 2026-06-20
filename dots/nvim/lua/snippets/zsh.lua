local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("sh", {
  s(
    "input",
    fmt(
      [[
read "{}?{}"
  ]],
      {
        i(1, "variable"),
        i(2, "pregunta"),
      }
    )
  ),
})

ls.add_snippets("sh", {
  s(
    "ifn",
    fmt(
      [=[
if [[ "${}" == {} ]]; then
  
fi
  
  ]=],
      {
        i(1, "valor1"),
        i(2, "valor2"),
      }
    )
  ),
})

ls.add_snippets("sh", {
  s(
    "shebang",
    fmt(
      [[
#!/usr/bin/env zsh
  ]],
      {}
    )
  ),
})
