-- Give wide tables relative column widths. The GFM reader leaves every
-- column at its default width, and Typst then sizes columns by their longest
-- unbreakable run, which starves long prose columns. Tables whose content
-- fits the text width at natural size are left alone.

local FITS = 90   -- summed longest-cell lengths below this need no widths
local CAP = 50    -- a column's share is capped at this many characters
local MIN = 11    -- and never below this, so short headers stay on one line

local CODE = 1.4  -- monospace runs are this much wider than prose per character
local LINE = 90   -- the text width, in prose characters

-- Longest unbreakable run in a cell, in prose characters. Typst cannot break
-- it, so a column narrower than this overflows into its neighbour.
local function word_len(cell)
  local w = 0
  cell.contents:walk({
    Str = function(s) w = math.max(w, #s.text) end,
    Code = function(c)
      for tok in c.text:gmatch("%S+") do w = math.max(w, CODE * #tok) end
    end,
  })
  return w
end

-- Length estimate in prose characters, with code spans weighted.
local function cell_len(cell)
  local code = 0
  cell.contents:walk({ Code = function(c) code = code + #c.text end })
  return #pandoc.utils.stringify(cell.contents) + (CODE - 1) * code
end

function Table(tbl)
  local n = #tbl.colspecs
  local longest, word = {}, {}
  for i = 1, n do longest[i] = 0; word[i] = 0 end
  local function scan(rows)
    for _, row in ipairs(rows) do
      for i, cell in ipairs(row.cells) do
        if i <= n then
          longest[i] = math.max(longest[i], cell_len(cell))
          word[i] = math.max(word[i], word_len(cell))
        end
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
  -- Each column keeps at least its longest word; the others share the rest
  -- in proportion, so a long word never spills into the next column.
  local frac, floor = {}, {}
  for i = 1, n do
    frac[i] = share[i] / sum
    floor[i] = math.min((word[i] + 1) / LINE, 0.5)
  end
  for _ = 1, n do
    local fixed, free = 0, 0
    for i = 1, n do
      if frac[i] <= floor[i] then fixed = fixed + floor[i] else free = free + frac[i] end
    end
    local scale = (1 - fixed) / free
    local changed = false
    for i = 1, n do
      if frac[i] <= floor[i] then frac[i] = floor[i]
      else
        frac[i] = frac[i] * scale
        if frac[i] < floor[i] then changed = true end
      end
    end
    if not changed then break end
  end
  for i = 1, n do
    tbl.colspecs[i] = { tbl.colspecs[i][1], frac[i] }
  end
  return tbl
end
