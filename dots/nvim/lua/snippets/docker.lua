local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

ls.add_snippets("yaml", {
  s(
    "docker",
    fmt(
      [[networks:
  {}
services:
  {}:
    networks:
      {}
  ]],
      {
        i(1, "Network1"),
        i(2, "Service1"),
        rep(1),
      }
    )
  ),
})
