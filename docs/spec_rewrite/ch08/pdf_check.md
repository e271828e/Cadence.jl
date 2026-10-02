# PDF layout check, chapter 8 rewrite

Limit: no PDF page renderer (pdftoppm) was installed, so the Read tool could not show page images. I checked text only, via pypdf text extraction of pages 25 to 52. The rewrite starts on p. 25 and ends on p. 52. Visual damage (spacing, page splits, fonts) was not judged.

Findings from text:
- No raw `**`, `*`, backticks, `[text][ref]`, `(#anchor)`, `$...$` or stray HTML outside code blocks.
- The only `#`, backtick and `|` hits are inside code blocks (pp. 27, 29, 46, 49, 51).
- Headings 8.1 (p. 25), 8.2 (p. 28), 8.3 (p. 38), 8.4 (p. 39), 8.5 (p. 39), 8.6 (p. 42), 8.7 (p. 48), 8.8 (p. 49) extract as heading lines with no raw marks.
- The 8.4 items run 1 to 5 on p. 39. The "Names" items 1 to 4 run on p. 28.
- The table in the u_types section (p. 31) extracts with three columns and three rows, no raw pipes.

No damage found in the text layer.
