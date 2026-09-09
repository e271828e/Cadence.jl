-- Give wide tables relative column widths. The GFM reader leaves every
-- column at its default width, and Typst then sizes columns by their longest
-- unbreakable run, which starves long prose columns. Tables whose content
-- fits the text width at natural size are left alone.

local FITS = 90   -- summed longest-cell lengths below this need no widths
local CAP = 50    -- a column's share is capped at this many characters
local MIN = 11    -- and never below this, so short headers stay on one line

local CODE = 1.4  -- monospace runs are this much wider than prose per character

-- Length estimate in prose characters, with code spans weighted.
local function cell_len(cell)
  local code = 0
  cell.contents:walk({ Code = function(c) code = code + #c.text end })
  return #pandoc.utils.stringify(cell.contents) + (CODE - 1) * code
end

function Table(tbl)
  local n = #tbl.colspecs
  local longest = {}
  for i = 1, n do longest[i] = 0 end
  local function scan(rows)
    for _, row in ipairs(rows) do
      for i, cell in ipairs(row.cells) do
        if i <= n then longest[i] = math.max(longest[i], cell_len(cell)) end
      end
    end
  end
  scan(tbl.head.rows)
  for _, body in ipairs(tbl.bodies) do scan(body.body) end
  local total = 0
  for i = 1, n do total = total + longest[i] end
  if total < FITS then return nil end
  local share, sum = {}, 0
  for i = 1, n do
    share[i] = math.min(math.max(longest[i], MIN), CAP)
    sum = sum + share[i]
  end
  for i = 1, n do
    tbl.colspecs[i] = { tbl.colspecs[i][1], share[i] / sum }
  end
  return tbl
end
