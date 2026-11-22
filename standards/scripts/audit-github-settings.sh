#!/usr/bin/env bash
# Reads the GitHub settings that code cannot show and prints one Markdown table row per repository.
# Read-only: every call is a GET. Needs `gh auth login` as an org owner/admin (otherwise fields show "n/a").
#
#   standards/scripts/audit-github-settings.sh [ORG]  > standards/audit/settings-$(date +%F).md
#
# Paste the output into the audit report. Unknown stays "n/a"; never fill a gap by assumption.
set -u
ORG="${1:-AIDEdgeInc-Lab}"
command -v gh >/dev/null || { echo "gh CLI not found" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "run: gh auth login" >&2; exit 1; }

api() { gh api "$@" 2>/dev/null; }

echo "# GitHub settings audit — $ORG — $(date -u +%FT%TZ)"
echo
tfa="$(api "orgs/$ORG" --jq '.two_factor_requirement_enabled' || echo n/a)"
owners="$(api "orgs/$ORG/members?role=admin" --jq 'length' || echo n/a)"
echo "- Org 2FA required: **${tfa:-n/a}** · Org owners: **${owners:-n/a}**"
echo
echo "| Repo | Vis | Archived | Default | Classic protection | Rulesets | Req. checks | Secret scan | Push protect | Dependabot sec. | Fork-PR approval | Token default | Envs | CODEOWNERS | SECURITY.md |"
echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"

gh repo list "$ORG" --limit 200 --json name,visibility,isArchived,defaultBranchRef \
  --jq '.[] | [.name, .visibility, (.isArchived|tostring), .defaultBranchRef.name] | @tsv' |
while IFS=$'\t' read -r name vis arch def; do
  r="$ORG/$name"
  prot="$(api "repos/$r/branches/$def/protection" --jq '"yes"' || echo "no/n-a")"
  reqchk="$(api "repos/$r/branches/$def/protection/required_status_checks" --jq '[.contexts[]?, .checks[]?.context] | unique | join(",")' || echo "n/a")"
  rs="$(api "repos/$r/rulesets" --jq 'length' || echo n/a)"
  sa="$(api "repos/$r" --jq '[.security_and_analysis.secret_scanning.status, .security_and_analysis.secret_scanning_push_protection.status, .security_and_analysis.dependabot_security_updates.status] | @tsv' || printf 'n/a\tn/a\tn/a')"
  ss="$(echo "$sa" | cut -f1)"; pp="$(echo "$sa" | cut -f2)"; ds="$(echo "$sa" | cut -f3)"
  fork="$(api "repos/$r/actions/permissions/fork-pr-contributor-approval" --jq '.approval_policy' || echo n/a)"
  tok="$(api "repos/$r/actions/permissions/workflow" --jq '.default_workflow_permissions' || echo n/a)"
  envs="$(api "repos/$r/environments" --jq '[.environments[]? | .name + (if ([.protection_rules[]? | select(.type=="required_reviewers")] | length) > 0 then "(reviewer)" else "" end)] | join(",")' || echo n/a)"
  co="no"; for p in CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS; do api "repos/$r/contents/$p" --jq .name >/dev/null && { co="yes"; break; }; done
  sec="no"; for p in SECURITY.md .github/SECURITY.md; do api "repos/$r/contents/$p" --jq .name >/dev/null && { sec="yes"; break; }; done
  echo "| $name | $vis | $arch | $def | $prot | ${rs:-n/a} | ${reqchk:-none} | ${ss:-n/a} | ${pp:-n/a} | ${ds:-n/a} | ${fork:-n/a} | ${tok:-n/a} | ${envs:-none} | $co | $sec |"
done
