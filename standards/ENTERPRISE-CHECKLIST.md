# Enterprise-readiness checklist — what is easy to forget

Companion to [`ENGINEERING-QUALITY-STANDARD.md`](ENGINEERING-QUALITY-STANDARD.md). Tests and CI are the visible part.
This list is the rest: access, accounts, settings, operations, data, and the questions an operator's security team or
an investor's technical reviewer will ask during a pilot or due diligence.

**Status column:** `Evidence` = verified in the 2026-10-13 audit (see `audit/`). `Unknown` = could not be read with
the tools available; run `standards/scripts/audit-github-settings.sh` or check the UI path given. Nothing here is
assumed done.

**Priority:** **P1** = a single failure can lose a pilot, a deploy path or the ability to ship. **P2** = expected in
diligence. **P3** = hardening.

## 1. Accounts and single points of failure

| P | Item | How to check | Status |
|---|---|---|---|
| P1 | **2FA enforced for every org member** | GitHub → Org → Settings → Authentication security | Unknown |
| P1 | **≥ 2 org owners** (bus factor). One person's lost phone must not lock the org | Org → People → filter Owners | Unknown |
| P1 | **OSGeo/QGIS plugin-repository account** that owns `velorona` on plugins.qgis.org: second maintainer added, recovery path documented. Publishing is manual, so this is a hard dependency | plugins.qgis.org → plugin → Manage maintainers | Unknown |
| P1 | **PyPI**: 2FA + recovery codes stored offline; ≥ 2 owners per project; trusted publisher registered for `pypi` **and** `testpypi` (workflow-runner has none for TestPyPI) | pypi.org → project → Settings | Evidence: workflow-runner comment says no TestPyPI publisher |
| P1 | **Cloudflare**: 2FA; API tokens scoped to *Pages: Edit* only; token owner and expiry recorded | Cloudflare → My Profile → API Tokens | Unknown |
| P1 | **Domains** `aidedgeinc.com`, `velorona.ai`: registrar lock, auto-renew, registrar 2FA, expiry date in a calendar | Registrar | Unknown |
| P2 | Machine/PAT inventory: every PAT, GitHub App and deploy key listed with owner, scope, expiry. Prefer GitHub App / OIDC over PATs | Org → Settings → Personal access tokens / Installed apps | Unknown |
| P2 | Offboarding procedure (remove access in GitHub, Cloudflare, PyPI, QGIS, registrar, Wix, Google) | Document | Unknown |

## 2. Repository settings (cannot be set from code)

| P | Item | How to check | Status |
|---|---|---|---|
| P1 | `main` protected: PR required, status check **`ci-gate`** required, no force-push, no deletion | Repo → Settings → Rules | Evidence (partial): `velorona-map` `main` reports `protected: false` (all 51 branches do), i.e. **no classic branch protection**. Repository *rulesets* are not visible through that field; confirm with `standards/scripts/audit-github-settings.sh`. Other repos: Unknown |
| P1 | **Bot-commit conflict decided** for `velorona-map` (daily "Update QGIS plugin stats" commit to `main`): ruleset bypass for the bot, or switch to PR + auto-merge | Standard §10 | Open decision |
| P1 | Secret scanning **and push protection** on all repos (public ones are free; private needs the plan to include it) | Repo → Settings → Code security | Unknown |
| P1 | Actions: default `GITHUB_TOKEN` = read-only; fork-PR workflows require approval; allowed actions restricted to SHA-pinned / selected | Repo/Org → Settings → Actions → General | Unknown |
| P1 | Environments with **required reviewer** for `pypi` (workflow-runner says it has one; geo-features, link-clearance, exposure, kpi-validator unverified) and for `production` deploys | Repo → Settings → Environments | Partly evidenced in workflow comments only |
| P2 | Dependabot alerts + security updates enabled; Dependabot config present (only `aei-geo-features`, `aei-3gpp-kpi-validator` have one) | Repo → Insights → Dependency graph | Evidence: 2 of 13 audited repos |
| P2 | Private vulnerability reporting enabled on public repos; org-default `SECURITY.md` (this repo) | Repo → Security | `SECURITY.md` exists in 2 of 6 public repos; org default added here |
| P2 | `CODEOWNERS` on code repos | Repo files | Evidence: 0 of 13 |
| P2 | `LICENSE` on every repo that is public or distributed. Missing in 6 private repos: `aidedge-velorona-web`, `velorona-demo`, `velorona-libraries`, `aei-microwave-weather-app`, `velorona-core-private`, `velorona-simulations` (private, but decide: a missing license means "all rights reserved", which may be intended for core IP) | Repo files | Evidence |
| P3 | Auto-delete merged branches; prune stale branches (Map has `backup/wip-20261002` and many `claude/*`) | Repo → Settings → General | Evidence: stale branches listed |
| P3 | Archive dead repos (`legacy-platform`, `*-legacy`, `operational-intelligence-methods-legacy`) so nobody builds on them | Repo → Settings → Archive | Unknown |

## 3. Supply chain

| P | Item | Status |
|---|---|---|
| P1 | Third-party Actions pinned to commit SHAs. Audit: **52 unpinned `uses:` refs** across 6 of the 7 repos that have workflows (demo 3, geo-features 13, workflow-runner 7, link-clearance 7, kpi-validator 15, link-exposure 7); `velorona-map` is already fully pinned, as is the plugin PR | Evidence |
| P1 | No long-lived PyPI tokens; OIDC trusted publishing only | Evidence in 3 publish workflows |
| P2 | PyPI **attestations** present on each release page (provenance a reviewer can verify). Check the release page of the latest version after the next publish | Unknown |
| P2 | Dependency audit in CI (`pip-audit`/`npm audit`), advisory first, then blocking | Added as reusable lane |
| P2 | **License compatibility** of the shipped plugin: plugin `GPL-2.0-or-later` consumes libraries licensed Apache-2.0. Get a one-time written opinion before a commercial pilot; do not assume | Needs legal check |
| P3 | SBOM for deployable artifacts (CycloneDX) attached to releases | Not started |
| P3 | Pin container images (`qgis/qgis`) by digest once lanes are required | Not started |

## 4. Operations

| P | Item | Status |
|---|---|---|
| P1 | **Rollback rehearsed once** per deployable (Cloudflare Pages dashboard rollback + the `git revert` that restores "main == production"). A rollback never tried is a guess. See [`RELEASE-AND-ROLLBACK.md`](RELEASE-AND-ROLLBACK.md) | Not rehearsed (no evidence) |
| P1 | **External uptime monitor** for `map.velorona.ai`, `velorona.ai`, `aidedgeinc.com`, `demo.velorona.ai` (separate from GitHub cron, which is best-effort and can skip runs) | Unknown |
| P2 | Stage C failure **alerts a human** (issue/e-mail), not only a red run nobody sees | Plugin: yes (issue). Map: not yet. Libraries: not yet |
| P2 | Non-git state backed up: Cloudflare Pages env vars list, DNS export, Wix site (`aidedge-wix-backup` exists), PyPI/plugin metadata | Partly |
| P2 | Incident record template and a place to keep them (`docs/incidents/`) | Not started |
| P3 | Cost guardrails: Actions minutes budget, concurrency groups (`cancel-in-progress` for PRs) | Plugin PR: yes |

## 5. Data, claims and third-party terms (specific to Velorona)

| P | Item | Why it matters |
|---|---|---|
| P1 | **Public/private boundary**: no operator data, testbed data, partner material or PII in any public repo; `velorona-field-data`, `real-telemetry-datasets`, `velorona-core-private` private | Pilot trust; the org README already promises this |
| P1 | **Synthetic vs real data is always labelled**, and a test guards it (Map PR #25 adds `test_no_synthetic_in_production.py`) | "Real-data proof" is the product's credibility |
| P1 | **No claim beyond evidence** in READMEs, sites, decks: no validation rates, customers or performance numbers that are not in a cited artifact. `velorona-core-private/CANONICAL_CLAIMS.md` is the source of truth; add a CI check that public text does not contain banned phrases | Funding and operator due diligence |
| P2 | Third-party data/tile terms reviewed for **production** use and attribution shown: CelesTrak terms, FCC ULS, ISED, Open-Meteo, **OpenStreetMap tile usage policy** (Map loads `*.tile.openstreetmap.org` directly; check current policy and consider a tile provider before real traffic) | Terms violations can cut the data feed mid-pilot |
| P2 | Privacy statement + cookie/analytics note for sites (Cloudflare Web Analytics is injected) | Operator procurement |

## 6. Compatibility and lifecycle

| P | Item | Status |
|---|---|---|
| P2 | **Python 3.9 reached end-of-life in October 2025.** Libraries still test 3.9 and do not test 3.13/3.14. Decide: drop 3.9 (raise `requires-python`) and add current versions to the matrix | Evidence: matrix is 3.9–3.12 in 4 library workflows |
| P2 | Support policy written per product (supported QGIS versions: plugin declares 4.0–4.99; library Python range; browsers for the Map) | Partly |
| P2 | Versioning + changelog + tag discipline; every release has a tag, notes, and a recorded artifact checksum | Plugin: changelog yes, checksum now added in CI. Published 1.1.7 zip has 62 files vs 64 from a fresh build of `main`; cannot be explained without a recorded checksum |
| P3 | Deprecation policy for library APIs consumed by the plugin (`aei-link-clearance>=0.2.0,<0.3` already pins a range) | Evidence of ranges |

## 7. What to hand an operator or investor ("assurance pack")

One page, regenerated from evidence, never from memory: CI status per product, last Stage C result and date, branch
protection screenshot, dependency audit result, data-classification statement, rollback procedure, list of known
limitations. Build it from this standard's outputs when the first pilot conversation needs it, not before.
