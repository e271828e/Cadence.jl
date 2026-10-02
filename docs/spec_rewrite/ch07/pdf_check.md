# PDF check, rewrite part (pages 9-16)

Clean. Text extracted with pypdf (scratch_pdf/all.txt).

- No raw markdown leaks (`**`, `][`, `](#g-`, backticks, `<a id`) in either part.
- Headings 7., 7.1-7.5 and Stores / Workspace / Idioms present.
- Numbering intact: 7.2 consumers 1-4 and author rules 1-3; 7.4 steps 1-4.
- 14 bullets, matching chapter_new.md (3+5, 3, 3). Logging bullet continuation paragraph present (indent not verifiable in text).
- Both code blocks present. Citations (section and D- links) render as text. Companion section present.
- No missing paragraphs.

Shared with the original, not rewrite-specific: `::` and `<:` render as `=:` in code and prose (font glyph issue); soft hyphens appear in extracted text.
