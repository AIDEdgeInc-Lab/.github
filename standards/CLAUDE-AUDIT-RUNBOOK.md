# Claude Code runbook — organization-wide engineering quality audit

How to re-run (or continue) the quality audit and rollout with Claude Code. Keep this file current; it is the
institutional memory so the prompt never has to be re-invented or re-explained.

Run it from a Claude Code session that has GitHub access to the repositories to be audited (attach them with
`add_repo`; use `access: push` only for repositories where changes will be made). Start with:

> Read `standards/ENGINEERING-QUALITY-STANDARD.md` and `standards/CLAUDE-AUDIT-RUNBOOK.md` in
> `AIDEdgeInc-Lab/.github`, then run the audit prompt below. Report using the evidence vocabulary in §9 of the standard.

## The prompt

```text
# Organization-Wide Engineering Quality Audit — AID Edge & Velorona

My goal is to establish a consistent engineering quality standard across all repositories I own or maintain.

Start by discovering and auditing the relevant repositories, including Velorona Map, the QGIS plugin, Velorona.ai,
AID Edge websites, libraries, SDKs, and other maintained projects.

## 1. Audit existing systems first
For each repository, inspect:
- Existing GitHub Actions workflows and CI checks.
- Unit, integration, browser, and end-to-end tests.
- Security and dependency checks.
- Branch protection and required status checks.
- Deployment workflows, release procedures, and rollback options.
- Existing production smoke tests.
Create a repository inventory and gap report before making broad changes.

## 2. Establish three quality stages
Stage A — Pull Request CI: run relevant automated tests and checks before changes can be merged.
Stage B — Release Validation: validate the exact release candidate, dependencies, package artifacts, compatibility,
and runtime requirements.
Stage C — Post-Deployment Verification: run appropriate smoke tests after deployment. Verify actual application
behavior, not merely an HTTP 200 response or a successful build.

## 3. Adapt checks to each repository
Use browser and application tests for websites, real supported runtime tests for QGIS, and packaging and
compatibility tests for libraries and SDKs. Share reusable workflows where practical, but do not force identical
test suites onto different project types.

## 4. Preserve operational safety
- Respect existing repository permissions and branch protections.
- Never expose credentials, secrets, or private code.
- Do not overwrite unrelated work.
- Do not merge or deploy changes when required checks fail.
- Respect rate limits when testing external services and real data sources.
- Clearly distinguish code defects, flaky tests, and external-service failures.
- Preserve existing production behavior unless an approved change requires otherwise.

## 5. Roll out incrementally
First audit every relevant repository. Then implement and validate the approach on Velorona Map and the QGIS
plugin. Once the approach is proven, extend it to the remaining repositories through focused, reviewable changes.
Reuse existing workflows rather than creating duplicates.

## 6. Report evidence accurately
For each repository, report: current state and identified gaps; workflows created or improved; tests actually
executed and their results; pull requests and commit SHAs; merge and deployment status; production smoke-test
results; remaining blockers and required approvals.
Never describe a stage as implemented, tested, merged, deployed, or production-verified unless there is evidence
for that specific status.

Complete all work that can be performed safely and autonomously. Ask for approval only when permissions,
production risk, or a genuine external blocker requires it.
Begin with the audit and inventory. Do not make broad changes before understanding the existing configuration.
```

## Operating notes (learned on the first run, 2026-10-13)

1. **Look for parallel work before writing anything.** List open PRs, recent workflow runs and `claude/*` branches in
   each repo first. On the first run, `velorona-map` already had a browser-checks workflow (PR #28), a production-verify
   workflow and a separate `prod-smoke` branch, written by other sessions the same night. Adding a third would have
   created conflicts. Contribute the missing piece, or consolidate, instead.
2. **Pin Actions to the peeled commit SHA.** `git ls-remote --tags` on an annotated tag returns the tag object, not the
   commit. Use `git ls-remote <repo> refs/tags/<tag> refs/tags/<tag>^{}` and take the `^{}` line when present.
3. **Test the logic you can, state what you cannot.** The authoring sandbox cannot reach `map.velorona.ai`, `unpkg.com`,
   `plugins.qgis.org` or Docker. Run the real commands locally where possible, then let the PR's Actions run be the
   evidence for the rest, and read its logs (job logs, not only the green tick) before claiming anything.
4. **A fast green is suspicious.** Open the log and look for the actual assertions (`62/62 checks passed`), not just the
   step conclusion.
5. **Branch protection and rulesets are not readable with the GitHub MCP tools.** Run
   `standards/scripts/audit-github-settings.sh` with `gh auth login` and paste the output into the audit report.
6. **Clone repositories one at a time** (the session git proxy caps concurrent operations), shallow, with a long timeout.
   Public repositories can be read anonymously; use `add_repo access: push` only where changes will be pushed.
7. **Do not invent counts.** Counts in reports (workflows, tests, unpinned refs) must come from a command run in the
   session; keep the command in the report.
8. **New gates start advisory** and are promoted by rule (standard §7). Do not make a lane required on its first green.
9. **Merging a Map PR deploys to production** (`main` auto-deploys). Never merge Map PRs on the owner's behalf; say
   clearly in each PR that merging deploys.

## "Mode check"

When asked for a mode check, answer in four lines: current mode (CTO / Execution Coach / …), the real decision on the
table, the next action, and what to stop doing. If work is looping on polish: *"Good enough. No more changes."* and
redirect to the pilot, funding or operator conversation it was meant to serve.
