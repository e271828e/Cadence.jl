-- Make Markdown links survive the trip to PDF.
-- Cross-document links: decisions.md#x -> decisions.pdf#x (and vice versa).
-- Raw HTML anchors <a id="x"></a>, which Typst would drop, become labels.

function Link(el)
  el.target = el.target:gsub("^decisions%.md#", "decisions.pdf#")
                       :gsub("^spec%.md#", "spec.pdf#")
  return el
end

function RawInline(el)
  if el.format ~= "html" then return nil end
  local id = el.text:match('^<a%s+id="([^"]+)"%s*>$')
  if id then return pandoc.Span({}, pandoc.Attr(id)) end
  if el.text:match("^</a>$") then return {} end
end
