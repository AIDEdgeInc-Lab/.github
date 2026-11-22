# AID Edge Inc. — `.github` (organization defaults and engineering standards)

This repository holds (1) the organization profile, (2) default community-health files, and (3) the **engineering
quality standard** with its reusable workflows. It is public: never add operator data, partner material, secrets or
private implementation detail here.

## Before changing anything about CI, releases, testing or repository settings

1. Read `standards/ENGINEERING-QUALITY-STANDARD.md` (stages A/B/C, repository classes, evidence vocabulary).
2. Read `standards/CLAUDE-AUDIT-RUNBOOK.md` (operating notes learned on real runs).
3. List open PRs, recent workflow runs and `claude/*` branches in the target repository first. Parallel sessions
   routinely work in the same repository; extend or consolidate, do not duplicate.

## Rules

- Report status with the evidence vocabulary: Designed → Implemented → Validated locally → CI-verified → Merged →
  Deployed → Production-verified. Never claim a later word than the evidence supports.
- Pin third-party Actions to full (peeled) commit SHAs. Every workflow declares top-level `permissions:`.
- New gates start advisory and are promoted after 3 consecutive green runs on `main`.
- Do not merge or deploy with a failing required check. Merging to `velorona-map` `main` deploys to production.
- Separate observation from inference, lab evidence from pilot-ready evidence. No invented numbers, customers or
  validation results.

## Layout

- `standards/` — the standard, enterprise checklist, release/rollback, Claude runbook, `audit/` reports, `scripts/`.
- `.github/workflows/reusable-*.yml` — shared mechanics callable from any repo (pin callers to a commit SHA).
- `profile/README.md` — organization profile. `SECURITY.md`, `.github/PULL_REQUEST_TEMPLATE.md` — org defaults.
