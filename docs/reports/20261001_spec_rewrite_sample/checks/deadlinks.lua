-- Internal targets do not exist in an excerpt; keep the link look, drop the jump.
function Link(el)
  if el.target:match("^#") or el.target:match("^decisions%.md#") then
    el.target = "https://example.invalid/" .. el.target:gsub("^.*#", "")
  end
  return el
end
