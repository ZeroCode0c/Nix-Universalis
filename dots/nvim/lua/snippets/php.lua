local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local fmt = require("luasnip.extras.fmt").fmt
local types = require("luasnip.util.types")

ls.add_snippets("php", {
  s(
    "Route",
    fmt(
      [[
Route::{}('/', function () {{
    return Inertia::render('{}');
}})->name('{}');
  ]],
      {
        c(1, { t("get"), t("post") }),
        i(2, "Welcome"),
        i(3, "Home"),
      }
    )
  ),
})

ls.add_snippets("php", {
  s(
    "inertia",
    fmt(
      [[
Route::inertia('{}', '{}', ['{}' => '{}']);  
  ]],
      {
        i(1, "/about"),
        i(2, "about"),
        i(3, "user"),
        i(4, "Mike"),
      }
    )
  ),
})
