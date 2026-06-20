local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("lua", {
  s(
    "snipfmt",
    fmt(
      [=[
s("{}", fmt([[
{}
]], {{
  i(1, "{}"),
  c(2, {{ t("{}"), t("{}") }}),
}}))
]=],
      {
        i(1, "trigger"), -- trigger del snippet generado
        i(2, "Texto o código"), -- cuerpo del snippet generado
        i(3, "Placeholder"), -- texto literal para el snippet generado
        i(4, "True"), -- texto literal para el snippet generado
        i(5, "False"), -- texto literal para el snippet generado
      }
    )
  ),
})

-- Generador de snippet tipo fmt

ls.add_snippets("lua", {
  s(
    "snip",
    fmt(
      [[
ls.add_snippets("{}", {{ 
  {} 
  }})
]],
      {
        i(1, "python"),
        i(2, "s()"),
      }
    )
  ),
})
