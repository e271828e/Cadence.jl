-- Mark inline code as Julia so Typst highlights it like the fenced blocks.
-- GFM has no syntax for a language on single-backtick code.
function Code(el)
  if #el.classes == 0 then el.classes = { "julia" } end
  return el
end
