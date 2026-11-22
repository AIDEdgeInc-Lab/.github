# AID Edge / Velorona — Engineering Quality Standard

Version 1.0 · 2026-10-13 · Owner: Sara Khosravi, AID Edge Inc.

One shared standard for how code is tested, released and verified in production across every AID Edge and Velorona
repository. The **stages are common; the tests are not.** A website, a QGIS plugin and a PyPI library get different
checks, because they fail in different ways.

> A green CI run means the code passed the tests that exist. It does **not** mean the product works in production.
> Stage C exists because of that sentence.

## 1. Why this exists (priority order)

1. **Operator validation / pilot credibility.** A VP of Network Operations opening `map.velorona.ai` or installing the
   QGIS plugin must get something that works and tells the truth about its data. One broken demo costs a meeting.
2. **Real-data proof.** Tests that touch real data are kept separate from tests that depend on third-party uptime.
3. **Funding / due-diligence readiness.** Reviewers look at CI history, branch protection, release discipline and
   supply-chain hygiene. This standard makes those answerable with evidence.
4. **Low operating cost.** Small team. Prefer few, stable gates over many flaky ones.

## 2. The three stages

| Stage | Question it answers | When it runs | Blocks |
|---|---|---|---|
| **A — Pull-request CI** | Is this change safe to merge? | Every PR and push to `main` | Merge |
| **B — Release validation** | Is *this exact artifact* safe to ship? | Tag, release, or manual dispatch | Release / deploy |
| **C — Post-deployment verification** | Does what users actually get work? | After deploy / publish, then on a schedule | Nothing; it raises an alert and starts rollback |

Rules that apply to all three:

- **Build once, test that artifact, ship that artifact.** Stage B tests the zip/wheel/bundle that will be published, not
  the source tree. Stage C compares what is live against what Stage B produced (checksum, version, or deployed SHA).
- **A passing HTTP 200 is not a smoke test.** Stage C must assert application behaviour: the page loads *its data*,
  the map renders features, the package installs in a clean environment and imports, the plugin loads in a fresh
  profile. See §5.
- **A stage that has not run does not count.** See the evidence vocabulary in §9.

## 3. Repository classes and what each must have

Classify every repository once (record it in its README or `docs/QUALITY.md`). Required = must exist and be enforced.

| Class | Examples | Stage A (required) | Stage B (required) | Stage C (required) |
|---|---|---|---|---|
| **Web app / site** (deployed) | `velorona-map`, `aidedge-velorona-web`, `velorona-demo` | Unit tests; build; real-browser checks for core flows; link and publication checks; no-secrets scan | Preview deployment of the exact build, smoke-tested *before* production promotion where the platform supports it | Browser smoke on production: loads, real data present, key layers render, no console errors, deployed version = tested version; alert on failure |
| **Desktop plugin** (QGIS) | `velorona-qgis-plugin` | Unit tests; Qt6 enum check; static security scan; package build + content verification; real QGIS runtime lane | Tag = metadata = changelog; zip installed into a fresh profile in each supported QGIS version | Download what the plugin repository serves and verify it; open an issue on failure |
| **Library / SDK** (PyPI) | `aei-geo-features`, `aei-link-clearance`, `aei-microwave-link-exposure`, `aei-workflow-runner`, `aei-3gpp-kpi-validator` | Tests across the supported Python matrix; build; `twine check --strict`; wheel ships no tests/dev files; clean-venv install + import | Tag = package version; OIDC trusted publishing; protected `pypi` environment with reviewer; tests re-run on the release commit | Wait for the version on the index, install it in a clean venv, import, compare version (`reusable-pypi-verify.yml`) |
| **Private core / IP** | `velorona-core-private` | Tests that exist; secret scan; dependency audit | n/a until packaged | n/a |
| **Data / research / notebooks** | `real-telemetry-datasets`, `velorona-field-data`, papers | No CI required. **Required:** private-by-default, secret scan, no raw operator data in public repos, data-classification note | n/a | n/a |
| **Archive / legacy** | `legacy-platform`, `*-legacy` | Archive the repository (read-only) | n/a | n/a |

Do not force an identical suite on different classes. Do force the same *vocabulary*, *evidence rules* and
*promotion rules*.

## 4. Naming and enforcement

- Every repo exposes **one** stable required check named **`ci-gate`**, an aggregator job that depends on all required
  lanes (`if: always()`, fails unless every needed job succeeded). Branch protection requires only `ci-gate`. Matrix
  job names change; the gate name does not.
- Workflow files: `ci.yml` (Stage A), `release-validate.yml` (Stage B), `post-deploy-smoke.yml` or
  `published-verify.yml` (Stage C), `codeql.yml`, `publish.yml`.
- Shared logic lives in this repository as reusable workflows
  (`.github/workflows/reusable-*.yml`). Callers pin them to a **full commit SHA**.
- Project-specific tests stay in the project. Share *mechanics* (matrix, build, verify, pin-check), not *assertions*.

## 5. What a real smoke test asserts

A Stage C check is acceptable only if it fails when the product is broken but the server is up. Minimum content:

- **Web:** the app shell loads; its primary dataset is fetched and non-empty (e.g. `fixedServiceData.links.length > 1000`
  for the Map); at least one layer renders features; no uncaught page errors; the deployed assets equal the tested
  commit's assets (hash/SHA parity), not just "something is up".
- **Plugin:** the zip served by the plugin repository passes structural verification and its version equals the
  published version.
- **Library:** `pip install pkg==version` in a clean venv on the real index, import succeeds, installed version equals
  the released version.
- **Read-only.** Smoke tests never write to production data or call paid/rate-limited APIs more than once per run.
  Live third-party sources are contacted only on manual dispatch or a low-frequency schedule.

## 6. Failures: classify before reacting

Every red run is exactly one of these. Write the class in the PR or issue.

| Class | Meaning | Response |
|---|---|---|
| **Defect** | Our code or our package is wrong | Fix. Never skip or delete the test to get green. |
| **Flaky** | Passes and fails on identical code (timing, race) | Open an issue with owner and expiry date; make the test robust or move it to the advisory lane. A flaky test may be *non-blocking*, never *deleted silently*. |
| **External** | Provider outage, rate limit, CDN, index delay | Do not block merges on it. Run such tests on a schedule (advisory lane); retry only for propagation delay. |
| **Infrastructure** | Runner, registry, quota | Re-run once. A second failure is real until proven otherwise. |

Rules: no `skip`, `xfail`, `continue-on-error` or timeout increase added merely to make a run pass. Allowed skips are
**listed by exact test ID** in the repo (see `tools/check_skips.py` in the QGIS plugin). A new skip fails CI.

## 7. Promotion model for new gates

New gates start **advisory** (`continue-on-error: true`, not in `ci-gate`). Promote to required after **3 consecutive
green runs on `main`** and a written note of the observed failure rate. Demote a required gate only with a dated issue
explaining why. This is how real-browser and real-QGIS lanes enter without blocking delivery on day one.

## 8. Supply-chain and safety baseline (all classes)

- Third-party Actions pinned to **full commit SHAs** with the version as a trailing comment. (Peeled commit SHA, not the
  tag-object SHA. Verify with `git ls-remote <repo> refs/tags/<tag> refs/tags/<tag>^{}`.)
- Every workflow declares top-level `permissions:` (default `contents: read`); jobs elevate individually.
- `actions/checkout` with `persist-credentials: false` unless the job pushes.
- Workflow inputs and event fields are passed through `env:`, never interpolated into `run:` scripts
  (script-injection hygiene).
- Publishing uses **OIDC trusted publishing** (no long-lived PyPI tokens) and a **protected environment with a required
  reviewer**. Cloudflare tokens are scoped to *Pages: Edit* only.
- Dependabot for `github-actions` and the language ecosystem, monthly, grouped.
- Secret scanning + push protection enabled; CodeQL on public Python/JS repos; dependency audit (advisory → blocking).
- `.env*`, keys and operator data are never committed. Test fixtures that *look like* secrets (e.g. redaction tests)
  are allowlisted explicitly and named in the scanner config.
- **Rate limits and real data:** tests must not hammer third-party services; one request per source per run, back-off
  after any non-200, no retries in loops. Data from operators or testbeds stays in private repositories.
- Respect branch protections and existing work: never force-push shared branches, never merge or deploy with a failing
  required check, never overwrite another contributor's open branch.

## 9. Evidence vocabulary (use these words exactly)

Do not write a stage up as better than its evidence.

| Word | Requires |
|---|---|
| **Designed** | A written plan or file exists. Nothing ran. |
| **Implemented** | The change is committed on a branch. |
| **Validated locally** | Commands were run in an authoring environment; name them and the result. |
| **CI-verified** | The workflow ran on GitHub Actions at a named commit SHA and passed; link the run. |
| **Merged** | Merged to the default branch; name the PR and merge SHA. |
| **Deployed** | The deploy job succeeded; name the deployment ID / version. |
| **Production-verified** | Stage C ran against production after that deploy and passed; link the run. |

Every report states, per repo: current state, gaps, workflows created or changed, **tests actually executed and their
results**, PR links and SHAs, merge/deploy status, production smoke result, blockers and approvals needed.
"Not run" and "not reachable from this environment" are valid and expected entries.

## 10. Branch protection baseline (repository settings; cannot be set from code)

For `main` of every repo in classes Web, Plugin, Library, Core:

- Require a pull request before merging (admin bypass allowed for the owner while the team is one person).
- Require status check **`ci-gate`** (and nothing else) and require branches to be up to date.
- Block force pushes and deletion of `main`.
- Require signed commits: optional, decide later.
- **Bot-commit exception:** `velorona-map` has a scheduled job that commits to `main` (`Update QGIS plugin stats`). A
  strict "PR required" rule would break it. Either grant that bot bypass in a ruleset, or change the job to open and
  auto-merge a PR. Decide before enabling the rule.

Check current state with `standards/scripts/audit-github-settings.sh` (needs `gh auth login`).

## 11. Adoption order

1. Audit and gap report (`standards/audit/`).
2. Prove the pattern on the two revenue-facing artifacts: **Velorona Map** and the **QGIS plugin**.
3. Roll to libraries (reusable workflows), then the websites, then private core.
4. Review the standard after each new repository class or incident. Change it by PR here.

See also: [`ENTERPRISE-CHECKLIST.md`](ENTERPRISE-CHECKLIST.md) (things easy to forget),
[`RELEASE-AND-ROLLBACK.md`](RELEASE-AND-ROLLBACK.md), [`CLAUDE-AUDIT-RUNBOOK.md`](CLAUDE-AUDIT-RUNBOOK.md).
