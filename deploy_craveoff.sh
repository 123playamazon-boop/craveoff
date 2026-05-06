#!/usr/bin/env bash
# Crave-Off — initial deploy script
# Creates the GitHub repo (if it doesn't exist) and uploads all files.
# Usage:
#   export GITHUB_TOKEN=ghp_xxx     # fine-grained PAT with repo:create + contents:write
#   bash deploy_craveoff.sh

set -euo pipefail

OWNER="123playamazon-boop"
REPO="craveoff"
DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "❌ GITHUB_TOKEN not set. Create a fine-grained PAT at https://github.com/settings/personal-access-tokens"
  echo "   Scope needed: repo:create + contents:write on $OWNER/$REPO"
  exit 1
fi

# ----- 1. Create repo if it doesn't exist -----
echo "🔍 Checking if $OWNER/$REPO exists..."
STATUS=$(curl -sS -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO")

if [[ "$STATUS" == "404" ]]; then
  echo "🆕 Creating repo $OWNER/$REPO..."
  # Organization? Try user endpoint first:
  CREATE_STATUS=$(curl -sS -o /tmp/craveoff_create.json -w "%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$REPO\",\"private\":false,\"auto_init\":true,\"description\":\"Crave-Off funnel — advertorial + quiz + checkout\"}")
  if [[ "$CREATE_STATUS" != "201" ]]; then
    # Fall back to org endpoint
    curl -sS -X POST \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/orgs/$OWNER/repos" \
      -d "{\"name\":\"$REPO\",\"private\":false,\"auto_init\":true,\"description\":\"Crave-Off funnel\"}" > /dev/null
  fi
  echo "   ✓ created"
  sleep 2
elif [[ "$STATUS" == "200" ]]; then
  echo "   ✓ repo already exists"
else
  echo "❌ GitHub returned HTTP $STATUS — check your token"
  exit 1
fi

# ----- 2. Upload files -----
upload() {
  local LOCAL="$1"
  local REMOTE="$2"
  local SIZE=$(wc -c < "$LOCAL" | tr -d ' ')
  printf "→ %-40s (%'d B)\n" "$REMOTE" "$SIZE"
  local B64=$(base64 -i "$LOCAL" | tr -d '\n')
  # Check for existing SHA (for updates)
  local SHA=$(curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$OWNER/$REPO/contents/$REMOTE" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha',''))" 2>/dev/null || echo "")
  local PAYLOAD
  if [[ -n "$SHA" ]]; then
    PAYLOAD=$(python3 -c "import json,sys; print(json.dumps({'message':'deploy craveoff','content':sys.argv[1],'sha':sys.argv[2]}))" "$B64" "$SHA")
  else
    PAYLOAD=$(python3 -c "import json,sys; print(json.dumps({'message':'deploy craveoff','content':sys.argv[1]}))" "$B64")
  fi
  local RESP=$(curl -sS -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$OWNER/$REPO/contents/$REMOTE" \
    -d "$PAYLOAD")
  local HASH=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('commit',{}).get('sha','ERR')[:7])")
  echo "   ✓ commit $HASH"
}

echo ""
echo "🚀 Uploading files to $OWNER/$REPO..."
echo ""

cd "$DIR"
for f in index.html quiz.html result.html checkout.html vercel.json README.md; do
  [[ -f "$f" ]] && upload "$f" "$f"
done

# Upload images if they exist
if [[ -d img ]]; then
  for img in img/*; do
    [[ -f "$img" ]] && upload "$img" "$img"
  done
fi

echo ""
echo "✅ Done. Next steps:"
echo "   1. Go to https://vercel.com/new → Import $OWNER/$REPO"
echo "   2. Deploy (framework: Other, root: /)"
echo "   3. You'll get: https://craveoff.vercel.app"
echo "   4. Replace Stripe link placeholders in checkout.html with your real Payment Links"
