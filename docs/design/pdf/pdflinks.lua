-- Make Markdown links survive the trip to PDF.
-- Cross-document links: with the metadata flag `combined` set, both documents
-- render into one PDF and `decisions.md#x` becomes the internal `#x`; without
-- it, each document renders alone and the link points at the sibling PDF
-- (which viewers such as Preview cannot follow, hence the combined default).
-- Raw HTML anchors <a id="x"></a>, which Typst would drop, become labels.

local combined = false

local function link(el)
  if combined then
    el.target = el.target:gsub("^decisions%.md#", "#"):gsub("^spec%.md#", "#")
  else
    el.target = el.target:gsub("^decisions%.md#", "decisions.pdf#")
                         :gsub("^spec%.md#", "spec.pdf#")
  end
  return el
end

local function anchor(el)
  if el.format ~= "html" then return nil end
  local id = el.text:match('^<a%s+id="([^"]+)"%s*>$')
  if id then return pandoc.Span({}, pandoc.Attr(id)) end
  if el.text:match("^</a>$") then return {} end
end

return {
  { Meta = function(m)
      combined = m.combined ~= nil and pandoc.utils.stringify(m.combined) == "true"
    end },
  { Link = link, RawInline = anchor },
}
