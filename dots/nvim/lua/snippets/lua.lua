local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node

local fmt = require("luasnip.extras.fmt").fmt

-- Nuevo snippet de LuaSnip
return s("mfn", { -- descripcion: Descripcion aquí
  c(1, {
    fmt("function {}.{}({})\n  {}\nend", {
      i(1, "mod"), -- antes era f(get_returned_mod_name, {})
      i(2, "fn_name"),
      i(3, "args"),
      i(4, "-- body"),
    }),
    fmt("function {}:{}({})\n  {}\nend", {
      i(1, "mod"), -- antes era f(get_returned_mod_name, {})
      i(2, "fn_name"),
      i(3, "args"),
      i(4, "-- body"),
    }),
  }),
})
