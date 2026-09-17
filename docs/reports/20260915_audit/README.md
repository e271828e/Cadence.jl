# Cadence audit — 2026-09-15/16

Start with the **[curated report](report.md)**.

- [Specification/source/test coverage](coverage.md)
- [Validation, reproduced cases and limits](validation.md)
- [Method and original baseline](method.md)
- Detailed reviews: [build](reviews/01_build.md),
  [execution](reviews/02_execution.md), [periphery](reviews/03_periphery.md),
  [services](reviews/04_services.md),
  [storage and diagnostics](reviews/05_storage_diagnostics.md),
  [independent test coverage](reviews/06_test_coverage.md),
  [grounding and document consistency](reviews/07_grounding_and_document_consistency.md)

The initial baseline was `865521a`; subsystem reviews were reconciled to
`f941c50`, followed by a complete review of the allowed delta to **`6986ad4`**.
Auto-publication and path-resolution fixes landed independently during pauses;
resolved findings are explicitly retired. The audit itself changed no source,
tests or design documents. Final validation and integrity records are linked above.

Final validation: **2,514/2,514 package assertions passed**; all nine targeted
probes completed. Probe success includes successful reproduction of defects.
