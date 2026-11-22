# Release and rollback — by repository class

Part of the [Engineering Quality Standard](ENGINEERING-QUALITY-STANDARD.md). Rule zero: **decide how you would undo a
release before you ship it, and rehearse it once.**

Severity decides speed, not process:

| Severity | Example | Action |
|---|---|---|
| **S1** | Production Map blank, or shows wrong/synthetic data as real; published package fails to install | Roll back **first**, diagnose after |
| **S2** | One layer or one feature broken; wrong value in one panel | Fix forward if the fix is small and Stage A/B pass, else roll back |
| **S3** | Cosmetic | Normal PR |

After any S1/S2: write a short incident note (what happened, how detected, time to detect, time to restore, what
check would have caught it) in `docs/incidents/` and add that check to Stage A or C. That is how this standard improves.

## Web apps on Cloudflare Pages (`velorona-map`, sites, demo)

Facts from the repositories: production deploys from `main` through GitHub Actions using Direct Upload
(`wrangler pages deploy`); Pages is not connected to Git. `velorona-map/docs/DEPLOY.md` states the invariant
**"`main` must always equal production"**, and a scheduled job also commits to `main`.

**Release**

1. PR passes `ci-gate` (Stage A). Merge to `main`.
2. Deploy workflow publishes. Record the Cloudflare **deployment ID** and the commit SHA in the release notes
   (`docs/DEPLOY.md` keeps a table).
3. Stage C smoke runs against production and must pass. If it fails: S1 procedure below.

**Rollback (S1)**

1. **Fastest:** Cloudflare dashboard → Workers & Pages → project → Deployments → pick the last good production
   deployment → *Rollback to this deployment*. Takes effect without a build.
2. **Same hour:** restore the invariant — `git revert -m 1 <merge-sha>` on `main` through a PR (admin bypass allowed for
   an S1). Merging redeploys the reverted tree, so production equals `main` again.
3. Run the Stage C smoke manually. Record result.
4. If step 1 was used and step 2 is not done, the next push or the daily stats job **will redeploy the bad build**.
   Do step 2 immediately.

**Do not** deploy manually from a feature branch (the bot commit would overwrite it; the invariant breaks).

**Preview-before-production (recommended, not yet implemented for the Map):** deploy the exact build to a Pages
preview branch, run the smoke test against that URL, then promote by deploying to the production branch. Gains a real
"deploy gate". Costs a second deploy and changes production behaviour, so it needs the owner's approval.

## QGIS plugin (`velorona-qgis-plugin`)

Publishing to plugins.qgis.org is **manual** (maintainer's OSGeo account).

1. Tag `vX.Y.Z` → `release-validate.yml` must pass (tag = `metadata.txt` = `CHANGELOG`, QGIS 4.0 and 4.2 clean install).
2. Download the `release-candidate` artifact. **Upload that exact zip.** Note the SHA-256 from `SHA256SUMS`.
3. `published-verify.yml` (daily, or run by hand) confirms the served zip verifies and has the new version.

**Rollback:** a plugin version number cannot be reused. In the plugin repository set the bad version to *unapproved*
(or delete it) so users stop receiving it, and upload a **higher** version containing the fix or the previous code.
Keep the last good zip and its checksum in the GitHub Release assets.

## Python libraries / SDKs (PyPI)

1. Tag `vX.Y.Z` equals the version in `pyproject.toml` (workflow checks it). Create the GitHub Release.
2. `publish.yml` builds once, then publishes through the protected `pypi` environment with a **required reviewer**
   (OIDC trusted publishing, no token). For risky changes run the manual `testpypi` target first.
3. Call `reusable-pypi-verify.yml` after the publish job: it waits for the version on the index, installs it in a clean
   venv, imports it and checks the installed version equals the release.

**Rollback:** never delete. **Yank** the bad release (pip then ignores it unless pinned exactly) and publish a patch
release. Downstream ranges (`aei-link-clearance>=0.2.0,<0.3`) pick up the patch automatically. If the yank affects the
QGIS plugin's requirement, release a plugin update the same day.

## Private core / data repositories

No release process until something is packaged. Never rewrite history on a repository that holds data; if a secret or
operator data was committed, treat it as a leak: rotate/notify first, clean history second.
