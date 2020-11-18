-- (c) 2020 Dominik Rehak, Vit Novotny.  Released under MIT license.
-- See the file LICENSE in the source for details.

local util = require("lunamark.util")
local lpeg = require("lpeg")
local entities = require("lunamark.entities")
local lower, upper, gsub, format, length =
  string.lower, string.upper, string.gsub, string.format, string.len
local P, R, S, V, C, Cg, Cb, Cmt, Cc, Ct, B, Cs =
  lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cg, lpeg.Cb,
  lpeg.Cmt, lpeg.Cc, lpeg.Ct, lpeg.B, lpeg.Cs

local M = {}

local parsers = {}

parsers.any = P(1)
parsers.spacing = S(" \n\r\t")
parsers.nonspacechar = parsers.any - parsers.spacing

parsers.Str = P("[Str \"")
parsers.Para = P("[Para ")
parsers.Emph = P("[Emph ")
parsers.Strong = P("[Strong ")

parsers.comma = P(",")
parsers.endstr = P("\"]")
parsers.closing = P("]")

parsers.Inline = V("Inline")

-- parse many p between starter and ender
parsers.between = function(starter, p, ender)
  -- return (starter * #parsers.nonspacechar * Ct(p * (p - ender2)^0) * ender2) -- this too
    -- P("[Str \"") * ((parsers.any - P("\""))^1 / writer.string) * P("\"]")
  return (starter * p * ender)
end

function M.new(writer, options)
  options = options or {}
  local larsers = {} -- locally defined parsers

  -- larsers.Str = parsers.between(parsers.any^1 / writer.string, parsers.Str, parsers.endstr)
  larsers.Str = parsers.between(P("[Str \""), ((parsers.any - P("\""))^1 / writer.string), P("\"]"))
  larsers.Para = parsers.between(parsers.Para, parsers.Inline, parsers.closing) / writer.paragraph
  larsers.Emph = parsers.between(parsers.Emph, parsers.Inline, parsers.closing) / writer.emphasis
  larsers.Strong = parsers.between(parsers.Strong, parsers.Inline, parsers.closing) / writer.strong

  local syntax = {
    "Inline", -- initial rule

    Inline = V("Str") + V("Para") + V("Emph") + V("Strong"),

    Str = larsers.Str,
    Para = larsers.Para,
    Emph = larsers.Emph,
    Strong = larsers.Strong,
  }


  -- larsers.inline = parsers.any^1 / writer.string
  -- larsers.inline = P("[Str \"") -- * (parsers.any^1 / writer.string) * P("\"]") * P(1)^0
  larsers.inline = Ct(syntax)

  local function create_parser(name, grammar)
    return function(str)
      local res = lpeg.match(grammar(), str)
      if res == nil then
        error(format("%s failed on:\n%s", name, str:sub(1,20)))
      else
        return res
      end
    end
  end

  local parse_inline
    = create_parser("parse_inline",
                    function()
                      return larsers.inline
                    end)

  parse_pandoc =
    function(inp)
      local result = { writer.start_document(), parse_inline(inp), writer.stop_document() }
      return util.rope_to_string(result), writer.get_metadata()
    end

  return parse_pandoc
end

return M
