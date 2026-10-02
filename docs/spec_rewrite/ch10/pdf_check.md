# PDF check of chapter.pdf (rewrite and companion)

Method: pypdf located the parts, and each page was rendered to PNG with sips and read by eye.

Note on page count: chapter.pdf has 39 pages, not 78 (page tree Count = 39). Original is pp. 1-18, rewrite pp. 19-38, companion p. 39 (one page, complete).

No raw markdown, raw math, raw links, stray asterisks or backticks, broken bullets or wrong heading levels were found. All `[§..][s..]` and `[term](#g-..)` links render as blue link text. All `$...$` math renders. The `####` labels ("The `t*` boundary", "`Δt` in the bundle") render as small headings with correct nesting. The chart matches the original (p. 12) character for character. Companion bullets and its code spans render correctly.

## Problems found (4, all minor or cosmetic)

1. **p. 33, §10.6, "Three registers per event" sketch (iteration pseudo-code fence).** Two comment-bearing lines are longer than the code box (about 85 columns), so they wrap onto a second line at column 0. The wrap breaks alignment: "the boundary" and "unconsumed" appear as stray flush-left lines. chapter_new.md line 929 (`boundary sweep ... due set fixed for the boundary`) and line 932 (`per event:  last ← now ... # a blocked edge stays unconsumed`). The original wrapped the same way at line 929 (original p. 13/14), so line 932 is new in the rewrite.

2. **p. 37, §10.7, "The wait" code block.** The line `remaining > 0 && sleep(remaining)   # coarse phase: ... (runs at most once)` overflows the box and wraps; "once)" lands alone at column 0. The following line `GC.safepoint()` comment wraps too: "through" sits alone at column 0 after `# a safepoint, never a yield: GC and signals get`. chapter_new.md lines 1195 and 1197. Fix: shorten the comments, to about 78 columns total.

3. **pp. 28-29, §10.5, "The two declaration forms" table.** The table splits across the page break. Page 28 holds the header and the `Relative` row at the bottom, page 29 repeats the header and holds the `Absolute` row. Columns, alignment and code spans are right. The original (p. 10) kept the table whole. chapter_new.md lines 649-652. Cosmetic, a page-break matter only.

4. **pp. 30-31, §10.5, "A worked example" first Julia fence.** The two `sample_times` code boxes are separated by a blank line inside one fence, and the fence splits across the page break (the second half starts p. 31, with a gap at the foot of p. 30). Alignment and comments render correctly. chapter_new.md lines 770-778. Cosmetic.

## Observations, not defects

- p. 21 (§10.4, intro chain) and p. 36 (§10.6, macro-sequence): the blockquotes render as indented plain text with no bar, and wrap at a hyphen ("root-/find") and before "budget)". The chain no longer carries the original's bold on tₙ and the bracketed group. chapter_new.md lines 180-181 and 1109-1110. Readable.
- p. 26 (§10.4, "Deployment constants"): the first line "Both localization constants are deployment, not implementation." is stretched by justification because of the long inline code span that follows. chapter_new.md line 492. Cosmetic.
- p. 31 chart (untyped fence, §10.5): no differences from the original p. 12. Dots align under the `k` digits, the `|` column lines up, and the `(D, Φ)` annotations are intact.
