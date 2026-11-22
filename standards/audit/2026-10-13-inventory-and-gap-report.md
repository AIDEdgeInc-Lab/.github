# Repository inventory and gap report — 2026-10-13

First run of the organization-wide engineering quality audit (see [`../CLAUDE-AUDIT-RUNBOOK.md`](../CLAUDE-AUDIT-RUNBOOK.md)).
Standard applied: [`../ENGINEERING-QUALITY-STANDARD.md`](../ENGINEERING-QUALITY-STANDARD.md).

**How to read this report.** Every number comes from a command run in the audit session; commands are listed in §8.
"Evidence" lines say what was observed. "Inference" lines are judgment. "Unknown" means the information could not be
read with the available tools; it is never filled by assumption. Status words follow standard §9.

## 1. Summary (what matters, in order)

| # | Finding | Evidence | Why it matters (pilot → revenue lens) |
|---|---|---|---|
| 1 | **The production Map has no PR-time test gate and no branch protection.** 687 pytest tests run only *after* merge, as the deploy gate. `main` reports `protected: false`; 51 branches exist. | `qgis-stats.yml`; Map PR #21, #28 text; GitHub branches API | A broken change reaches `main` before any test runs; that same run publishes `map.velorona.ai`, the page an operator opens first. |
| 2 | **Map has ~18 real-browser check scripts that were "run by hand" and not in CI**; another session added them in draft PR #28 (18 suites reported green at head `49cb1ef` after one re-run; the run at the latest head `ad606ef` concluded *failure*, cause not examined). Two overlapping post-deploy checks are in flight (`production-verify.yml`, `smoke-prod.yml`); neither alerts anyone. | `tests/*.py` docstrings; PR #28; runs 38325940601, 38329448348; branch `claude/prod-smoke` | Stage A/C for the Map are being built twice; consolidate before merging either. |
| 3 | **QGIS plugin had zero CI**, despite 333 tests, a QGIS E2E suite and packaging/verification tools. Draft PRs #15 and #16 say "No CI exists in this repository"; #17 says no QGIS runtime was available. Test dependency `requests` was undeclared (fresh install fails at collection). | `find .github`; PRs #15–17; clean-venv run | The plugin is the artifact operators install. Nothing proved it loads on the declared minimum QGIS. |
| 4 | **Real QGIS 4.0.3 (declared minimum) crashes at shutdown** after all 36 clean-install checks pass; QGIS 4.2 does not. Reproduced 2/2 on runners. | Run 38331941980; issue [#19](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/issues/19) | Found only because Stage B now tests the minimum version. Cause not established. |
| 5 | **`aidedge-velorona-web` (aidedgeinc.com + velorona.ai) has no CI; deploys are manual** (`npm run deploy:*:production` → `wrangler pages deploy`, guarded only by a clean-tree check; no workflow exists). It has `check:publication` and `check:noindex` scripts that nothing runs. | `package.json`, no workflows | Corporate and product sites are the first thing a VP or investor sees. |
| 6 | **`velorona-demo` deploys without running its 227 tests**; its only post-deploy check is HTTP 200 on `velorona-demo.pages.dev`, not the custom domain `demo.velorona.ai` that its commit history refers to. | `deploy.yml`; local `vitest` 227 passed | "200 OK" passes on a blank page. |
| 7 | **No library publish workflow runs tests or verifies the published package.** None of five `publish.yml` files contains `pytest`; only `aei-workflow-runner` checks tag = version. | grep in 5 workflows | A release can ship a version that fails to import; nobody finds out. |
| 8 | **52 third-party Action refs are not pinned to commit SHAs** across 6 of the 7 repos that have workflows. Two repos have workflows with no top-level `permissions`. | pin-check script, §8 | Supply-chain exposure; a standard diligence question. |
| 9 | **Governance files are thin**: Dependabot in 2 of 13 audited repos, `SECURITY.md` in 2, `CODEOWNERS` in 0; no `LICENSE` in 6 private repos (web, demo, libraries, weather-app, core-private, simulations). | file listing | Diligence checklist items; cheap to fix. |
| 10 | **Published QGIS 1.1.7 has 62 files; a fresh build of `main` has 64.** Unexplained: no checksum was ever recorded for the released zip. | `published-verify` run 38331824831 vs local `package.sh` | Release provenance gap. Stage B now records `SHA256SUMS`. |

## 2. Inventory (13 code repositories audited)

Class per standard §3. "Tests" = observed locally unless stated. All baselines were run in the audit sandbox
(Python 3.13, Node 22); CI results are from GitHub Actions runs linked in §5.

| Repo | Vis. | Class | Workflows before | Tests (local baseline) | Dependabot | SECURITY.md | CODEOWNERS | LICENSE |
|---|---|---|---|---|---|---|---|---|
| `velorona-map` | private | Web app | `qgis-stats.yml` (test → stats → deploy) | pytest **687 passed, 0 skipped** (152 s); 18 browser check scripts (not in CI) | no | no | no | yes |
| `aidedge-velorona-web` | private | Web app | none | **none** (no test files; 2 check scripts unused) | no | no | no | **no** |
| `velorona-demo` | private | Web app | `deploy.yml` | vitest **227 passed** (35 files); `oxlint` warnings only; `build` OK | no | no | no | **no** |
| `velorona-qgis-plugin` | public | Plugin | none (plus an experiment branch) | pytest **331 passed, 2 skipped** (333) | no | no | no | yes |
| `aei-geo-features` | public | Library | `ci`, `codeql`, `publish` | **33 passed** | **yes** | yes | no | yes |
| `aei-3gpp-kpi-validator` | public | Library | `ci`, `codeql`, `publish` | **40 passed** | **yes** | yes | no | yes |
| `aei-link-clearance` | public | Library | `ci`, `publish` | **51 passed** | no | no | no | yes |
| `aei-microwave-link-exposure` | public | Library | `ci`, `publish` | **220 passed** | no | no | no | yes |
| `aei-workflow-runner` | public | Library | `ci`, `publish` | **173 passed** (54 s) | no | no | no | yes |
| `velorona-libraries` | private | Library monorepo | none | 56 test files, **not executed** | no | no | no | **no** |
| `aei-microwave-weather-app` | private | App (`app.py`) | none | none | no | no | no | **no** |
| `velorona-core-private` | private | Core / IP | none | **none** (`tests/` holds `.gitkeep`) | no | no | no | no |
| `velorona-simulations` | private | Notebooks | none | none | no | no | no | no |

Library build checks run locally on all five (build, `twine check --strict`, wheel contains no tests/dev files,
install wheel in clean venv and import): **all pass**. Import names differ from repo names for two:
`aei_workflow` and `aei_mw_exposure`.

Library Python matrix in CI: 3.9, 3.10, 3.11, 3.12. **Python 3.9 reached end-of-life in October 2025**; 3.13+ is not tested.

### Not audited (outside the CI standard; baseline settings only)
Org research/data/docs: `pre-escalation-window`, `pre-escalation-window-paper`, `velorona-research-v2`,
`velorona-research-microwave-alarm-dataset`, `real-telemetry-datasets`, `velorona-field-data`, `cross-dataset-analysis`,
`resource-aware-degradation-analysis`, `network-degradation-patterns`, `pmads-method-exercise`, `velorona-technical-brief`,
`velorona-overview`, `velorona-founder-handbook`, `technical-docs`, `satellite-ntn`, `aidedge-wix-backup`,
`.github` (this repository; now has its own CI). Legacy: `legacy-platform`, `operational-intelligence-methods-legacy`,
`velorona-overview-legacy` — candidates to archive. Also 24 personal `Sara-Khosravi/*` repositories (forks, portfolio),
visible to the audit token; keep them separate from the company org.
**Required for those, not CI:** private by default (public ones: `velorona-overview`, `pre-escalation-window-paper`
must contain no operator or testbed data), secret scan, data-classification note.

## 3. Secret hygiene (working trees only; git history not scanned)

Regex scan of 7 credential patterns (AWS key id, GitHub tokens, `sk-` keys, Slack tokens, private-key blocks,
Cloudflare `cfut_`) over all 13 working trees, plus tracked `.env*`/`*.pem`/key files.

- **1 hit in 1 repo**: `velorona-map/tests/js/history.test.js:204`, a *deliberate fake credential* inside a
  "no secrets are persisted" redaction test. Not a leak. A secret scanner must allowlist this path or it will alert.
- 0 tracked `.env*` or key files in any repo.
- **Not done:** history scan (`gitleaks` over full history), GitHub secret-scanning alert state (needs repo admin read).

## 4. Settings that could not be read (Unknown)

The GitHub MCP tools expose neither rulesets, branch-protection rules, required checks, environment reviewers,
secret-scanning/push-protection state, Actions permissions nor org 2FA. `gh` in the sandbox fails authentication.
Only one signal was available: `GET branches` → `protected: false` for `velorona-map` `main` and all 50 other branches; `aei-geo-features` `main` reports `protected: true` (classic protection exists there; its required checks are unknown, and renaming CI jobs, as PR #22 does, may need a matching update). `aei-link-clearance`, `aei-microwave-link-exposure`, `aei-workflow-runner` and `aei-3gpp-kpi-validator` `main` report `protected: false`.

**Closing the gap (5 minutes, you):** run `standards/scripts/audit-github-settings.sh` with `gh auth login`, save the
output as `standards/audit/settings-2026-10-13.md`. The script is read-only (GET only). It was lint-checked
(`bash -n`, shellcheck) but **has not been executed** (no authentication in the audit environment).

## 5. Work performed in this session (status per standard §9)

| Repo | Change | PR / SHA | Stage | Status |
|---|---|---|---|---|
| `.github` | Standard, checklist, rollback, runbook, audit, reusable workflows, org defaults | [PR #6](https://github.com/AIDEdgeInc-Lab/.github/pull/6), branch `claude/upbeat-feynman-csli2s` | — | **Implemented**; hygiene workflow **CI-verified**, the other two reusable workflows **Validated locally** (below); **not merged** |
| `velorona-qgis-plugin` | `ci.yml` (unit ×2, enums, bandit, package, QGIS 4.0/4.2 offline suites, `ci-gate`), `release-validate.yml`, `published-verify.yml`, `qgis-live-e2e.yml`, `run_qgis_suite.py`, `check_skips.py`, `requirements-dev.txt`, dependabot, `docs/QUALITY.md` | [PR #18](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/pull/18), head `cdb6c03` | A, B, C | **CI-verified** (below, with one tolerated QGIS 4.0.3 teardown crash); **not merged**, not released |
| `aei-link-clearance` | same shared-CI change + `ci-gate` + `permissions` + dependabot | [PR #3](https://github.com/AIDEdgeInc-Lab/aei-link-clearance/pull/3), head `3e24262` | A | **CI-verified** (run 38490346981); **not merged** |
| `aei-microwave-link-exposure` | same (this is the Map's parity oracle and a plugin requirement) | [PR #6](https://github.com/AIDEdgeInc-Lab/aei-microwave-link-exposure/pull/6), head `67a6a1a` | A | **CI-verified** (run 38490353878); **not merged** |
| `aei-workflow-runner` | same + dependabot | [PR #2](https://github.com/AIDEdgeInc-Lab/aei-workflow-runner/pull/2), head `1cea195` | A | **CI-verified** (run 38490361378); **not merged** |
| `aei-3gpp-kpi-validator` | same; keeps its own no-optional-extras lane in `ci-gate` | [PR #7](https://github.com/AIDEdgeInc-Lab/aei-3gpp-kpi-validator/pull/7), head `6f38a41` | A | **CI-verified** (run 38490368182); **not merged** |
| `aei-geo-features` | `ci.yml` replaced by a call to the shared library CI + `ci-gate`; `publish.yml`/`codeql.yml` untouched (Dependabot PRs #18–#21 own them) | [PR #22](https://github.com/AIDEdgeInc-Lab/aei-geo-features/pull/22), head `005ddb9` | A | **CI-verified**; **not merged**; depends on `.github` PR #6 |
| `velorona-map` | `ci.yml`: pytest on pull requests + `ci-gate` | [PR #29](https://github.com/AIDEdgeInc-Lab/velorona-map/pull/29), head `d19ba45` | A | **CI-verified**; **not merged** (merging deploys; `web/` unchanged) |

### Evidence, plugin PR #18 (GitHub Actions, final head `cdb6c03`)
- Stage A run [38332599899](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/actions/runs/38332599899): `unit` 3.12 and 3.13 ✔ (331 passed, only the 2 allowlisted skips), `enums` ✔, `bandit` ✔,
  `package` ✔ (zip built + verified), `ci-gate` ✔. QGIS **4.0.3 and 4.2** offline suites ✔ (UI polish **62/62** read from the 4.0 log).
- Stage C run [38332599890](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/actions/runs/38332599890): downloaded the live **Velorona 1.1.7** from plugins.qgis.org, `verify_package.py` PASS (62 files).
- Stage B run [38332600021](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/actions/runs/38332600021): consistency ✔, full CI ✔, build ✔ (sha256 recorded), **clean install QGIS 4.2 ✔ (36/36, clean exit)**,
  **clean install QGIS 4.0 ✔ (36/36) with a warning**: the process died at shutdown. History of that lane: attempts 1 and 2 of run 38331941980 (before the wrapper) **failed** with `std::bad_alloc` abort (exit 134) after `36/36 passed`;
  the run above died with SIGSEGV (exit −11). Issue [#19](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/issues/19), classified *infrastructure / QGIS-runtime teardown*, cause **not established**.
  `run_qgis_suite.py` tolerates exactly "complete N/N pass + abort signal" and nothing else (11 unit tests incl. a real `os.abort()`).
- Not exercised: `qgis-live-e2e.yml` (weekly; first run after merge), and the issue-on-failure step of `published-verify.yml`.

### Evidence, Map PR #29
- Run 38332150383 @ `d19ba45`: `pytest (no skips allowed)` ✔ in 93 s on a runner; `ci-gate` ✔.

### Evidence, reusable workflows in `.github` (Validated locally only)
- `actionlint` 1.7.12 + shellcheck: clean on all workflows.
- The build/verify logic of `reusable-python-lib-ci.yml` run by hand against all five libraries: pass.
- `reusable-pypi-verify.yml` logic run against real PyPI: passes for `aei-geo-features 0.1.5`; fails correctly for a
  never-published version (404) and for a wrong import name.
- `reusable-workflow-hygiene.yml` pin/permission checks run over the 7 real repos: they correctly find the 52 unpinned refs.
- **CI-verified on a runner:** `reusable-workflow-hygiene.yml` (called by this repo's `ci.yml`; actionlint, pin check, permissions check and `ci-gate` all ran and passed: run [38332743132](https://github.com/AIDEdgeInc-Lab/.github/actions/runs/38332743132) @ `278468d`, PR [#6](https://github.com/AIDEdgeInc-Lab/.github/pull/6)).
- **CI-verified on a runner (2026-10-14):** `reusable-python-lib-ci.yml`, called from [aei-geo-features PR #22](https://github.com/AIDEdgeInc-Lab/aei-geo-features/pull/22) pinned to `b98a66f`: run [38489787139](https://github.com/AIDEdgeInc-Lab/aei-geo-features/actions/runs/38489787139) → `Test` on Python 3.9/3.10/3.11/3.12 ✔, `Build and verify distribution` ✔ (build, `twine check --strict`, wheel contents, clean-venv import), `Dependency audit` ✔ ("No known vulnerabilities found"), `ci-gate` ✔. One matrix leg (3.10) spent 2.5 min in `pip install` (runner/network variance, passed).
- **Not CI-verified**: `reusable-pypi-verify.yml` (needs a real release; its logic was verified against real PyPI locally).

## 6. Gap register by repository (what to do, in order)

**`velorona-map`** (revenue-facing; highest priority)
1. Merge [#29](https://github.com/AIDEdgeInc-Lab/velorona-map/pull/29) (PR-time pytest). Merging deploys an identical site.
2. Decide the bot-commit question, then enable branch protection requiring `ci-gate` (standard §10).
3. Consolidate in-flight work: keep `smoke-prod.yml` as the single Stage C; drop `production-verify.yml` (its marker string
   goes stale); replace `sleep 45` by polling for asset parity; open an issue on failure.
4. After #28 merges, fold `browser-checks.yml` into `ci.yml` via `workflow_call`; keep it advisory until 3 green runs on `main`.
   Known flaky: `remediation_browser_check` (main failed 2 of 5 on identical runners); `us_pack_browser_check` once.
5. Preview-then-promote deploy (needs your approval: changes production behaviour). `csp_browser_check` still not in CI.
6. Add Dependabot, `CODEOWNERS`. Allowlist the redaction-test fixture in any secret scanner.

**`velorona-qgis-plugin`**
1. Review/merge [#18](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/pull/18); then require `ci-gate`.
2. Root-cause [#19](https://github.com/AIDEdgeInc-Lab/velorona-qgis-plugin/issues/19); remove the tolerance.
3. Promote `qgis-offline` to required after 3 green runs on `main`.
4. At the next release: attach the verified zip and `SHA256SUMS` to the GitHub Release and upload *that* zip.
5. Open PRs #15–17 should be rebased onto #18 so they get CI; #16/#17 contain code that was "not run" in a QGIS runtime.

**`aidedge-velorona-web`** — add `ci.yml` (`npm ci`, `npm run build` which already runs `check:publication` and
`check:noindex`, link check), Playwright is already a dev-dependency; add a preview-deploy + smoke before the manual
production script; add `LICENSE`. Keep production deploy manual until a Stage C smoke exists.

**`velorona-demo`** — insert `npm run lint && npm test && npm run build` before the deploy job (they pass locally);
smoke `demo.velorona.ai` for content, not status 200; pin actions; add top-level `permissions`.

**Libraries (5)** — Stage A is done as five CI-verified PRs (geo-features #22, link-clearance #3, link-exposure #6, workflow-runner #2, kpi-validator #7); merge `.github` #6 first, then those. Still open, in order, one PR per repo (publish paths cannot be tested without publishing, so each needs your go-ahead):
1. Pin the remaining actions in `publish.yml` / `codeql.yml` (52 refs before these PRs; Dependabot PRs on geo-features and kpi-validator already bump them, merge those first to avoid conflicts).
2. Make `publish.yml` depend on a passing test run on the release commit; add the tag = version check (4 repos lack it).
3. Call `reusable-pypi-verify.yml` after the PyPI publish job (Stage C), and add `SECURITY.md` to 3 repos.
4. Protect `main` requiring `ci-gate` (only geo-features is protected today).
5. Decide Python 3.9 / add 3.13. Register a TestPyPI trusted publisher for `aei-workflow-runner`.

**Private core / libraries monorepo / weather app / simulations** — no CI until packaged, except: add tests for
`velorona-core-private` before anything is built from it; run `velorona-libraries`' 56 test files in CI;
`aei-microwave-weather-app` needs tests or an explicit "prototype" label.

## 7. Blockers and approvals needed (you)

| # | Decision / action | Why it is yours |
|---|---|---|
| 1 | Merge `.github` branch so the reusable workflows and defaults take effect | Org-wide defaults |
| 2 | Run `audit-github-settings.sh` and paste the result | Needs your GitHub authentication |
| 3 | Merge plugin PR #18 and Map PR #29 | Map merge deploys to production |
| 4 | Branch protection + the Map bot-commit decision | Changes how you ship |
| 5 | Preview-before-production for Map; manual publish workflow for the web repo | Changes production behaviour |
| 6 | Python 3.9 support decision | Public API commitment |
| 7 | One-time legal check on GPL-2.0-or-later plugin consuming Apache-2.0 libraries | Licensing risk before a commercial pilot |
| 8 | Production smoke of the Map from a network-enabled runner | The audit sandbox cannot reach `map.velorona.ai` or `unpkg.com`; **no production verification of the Map was possible** |

**Not production-verified:** nothing in this report is production-verified for the Map, the sites or the demo.
The plugin's published artifact was verified structurally (Stage C, run 38331824831).

## 8. Commands behind the numbers

```text
repos / visibility        mcp list_repos (limit 200)                       -> 13 code repos selected, rest listed in §2
workflow + file inventory find .github/workflows; ls -A; git ls-files | grep (manifests, tests, governance files)
unpinned actions          grep -nE '^\s*-?\s*uses:\s*[^./ ][^ ]*@' .github/workflows/*.yml | grep -vE '@[0-9a-f]{40}(\s|$)'
                          demo 3, geo-features 13, workflow-runner 7, link-clearance 7, kpi-validator 15, link-exposure 7 = 52; map 0
no top-level permissions  grep -qE '^permissions:' per workflow -> demo 1, link-clearance 1, link-exposure 1
secret scan               git grep -I -E '<7 patterns>' per repo; tracked .env/key files
peeled action SHAs        git ls-remote <repo> refs/tags/<tag> refs/tags/<tag>^{}
map pytest                pip install -e ".[dev]" aei-microwave-link-exposure==0.2.0; pytest -q -rs     -> 687 passed
plugin pytest             pip install -r requirements.txt pytest requests; pytest tests                 -> 331 passed, 2 skipped
demo                      npm ci; npm test (vitest) -> 227 passed; npm run lint (warnings); npm run build -> ok
libraries                 pip install -e ".[dev]"; pytest -> 33 / 51 / 220 / 173 / 40; python -m build; twine check --strict
PyPI versions             GET https://pypi.org/pypi/<pkg>/json -> geo 0.1.5, clearance 0.2.1, exposure 0.2.0, runner 0.1.1, kpi 0.1.2
Docker Hub QGIS tags      GET hub.docker.com/v2/repositories/qgis/qgis/tags -> 4.0.3, 4.2.2, 4.2.3 exist
branch protection signal  mcp list_branches (velorona-map, 51 branches) -> protected:false for all
```
