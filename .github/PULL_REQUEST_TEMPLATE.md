## What and why
<!-- One or two sentences. Link the issue or the operator/pilot need it serves. -->

## Class and stage touched
- Repository class: <!-- web app | plugin | library | private core | docs/data -->
- Stage: <!-- A: PR CI | B: release validation | C: post-deploy verification | none -->

## Evidence (use exactly these words; delete lines you cannot support)
- [ ] **Validated locally**: commands run and results:
- [ ] **CI-verified**: workflow run link and commit SHA:
- [ ] **Not run / not reachable from my environment**:

## Impact
- Merging this **deploys / publishes**: <!-- yes (what, where) | no -->
- Rollback: <!-- how to undo; see standards/RELEASE-AND-ROLLBACK.md -->
- Data: <!-- real | synthetic (labelled) | none --> · Secrets or private data touched: <!-- no -->

## If a check is red
Classify it: defect / flaky / external / infrastructure. Do not skip or delete a test to get green.
