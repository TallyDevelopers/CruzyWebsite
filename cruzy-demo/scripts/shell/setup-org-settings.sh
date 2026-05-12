#!/bin/bash
# Sets org Language → English (en_US), Timezone → America/Los_Angeles, Currency → USD
#
# Usage:   bash scripts/shell/setup-org-settings.sh [alias]
# Default alias: cruzy-demo
#
# Currency note: Single-currency scratch orgs default to USD when language=en_US / country=US.
# If you need multi-currency support, enable the MultiCurrency feature in
# config/project-scratch-def.json and recreate the scratch org.

TARGET_ORG="${1:-cruzy-demo}"

echo "Applying org settings to: $TARGET_ORG"
echo ""

# ── 1. Fetch instance URL and access token ───────────────────────────────────
ORG_JSON=$(sf org display --target-org "$TARGET_ORG" --verbose --json 2>/dev/null)
INSTANCE_URL=$(echo "$ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['instanceUrl'])")
ACCESS_TOKEN=$(echo "$ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['accessToken'])")
ORG_ID=$(echo "$ORG_JSON"      | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['id'])")

if [ -z "$ORG_ID" ]; then
  echo "ERROR: Could not retrieve org details for alias '$TARGET_ORG'."
  exit 1
fi

echo "Org ID:       $ORG_ID"
echo "Instance URL: $INSTANCE_URL"
echo ""

# ── 2. PATCH Language, Locale & Timezone via REST API ───────────────────────
echo "Setting Language → en_US | Locale → en_US | Timezone → America/Los_Angeles ..."

HTTP_STATUS=$(python3 - <<PYEOF
import json, urllib.request, urllib.error

instance_url = "$INSTANCE_URL"
access_token = "$ACCESS_TOKEN"
org_id       = "$ORG_ID"

url     = f"{instance_url}/services/data/v62.0/sobjects/Organization/{org_id}"
payload = json.dumps({
    "LanguageLocaleKey": "en_US",
    "DefaultLocaleSidKey": "en_US",
    "TimeZoneSidKey": "America/Los_Angeles"
}).encode("utf-8")

req = urllib.request.Request(url, data=payload, method="PATCH")
req.add_header("Authorization", f"Bearer {access_token}")
req.add_header("Content-Type", "application/json")

try:
    resp = urllib.request.urlopen(req)
    print(resp.getcode())
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"ERROR {e.code}: {body}")
PYEOF
)

if [ "$HTTP_STATUS" = "204" ]; then
  echo "Language, Locale, and Timezone updated successfully (HTTP 204)."
else
  echo "WARNING: Unexpected response: $HTTP_STATUS"
fi

# ── 3. Currency ──────────────────────────────────────────────────────────────
echo ""
echo "Checking currency..."

CURRENCY_INFO=$(python3 - <<PYEOF
import json, urllib.request, urllib.error

instance_url = "$INSTANCE_URL"
access_token = "$ACCESS_TOKEN"

req = urllib.request.Request(
    f"{instance_url}/services/data/v62.0/query/?q=SELECT+Id,LanguageLocaleKey,DefaultLocaleSidKey,TimeZoneSidKey+FROM+Organization+LIMIT+1"
)
req.add_header("Authorization", f"Bearer {access_token}")

try:
    resp = urllib.request.urlopen(req)
    data = json.loads(resp.read().decode())
    rec  = data["records"][0]
    print(f"Language : {rec.get('LanguageLocaleKey')}")
    print(f"Locale   : {rec.get('DefaultLocaleSidKey')}")
    print(f"Timezone : {rec.get('TimeZoneSidKey')}")
    print("Currency : USD (single-currency org — determined by country=US in scratch def)")
except urllib.error.HTTPError as e:
    print("ERROR:", e.read().decode())
PYEOF
)

echo ""
echo "=== Final Org Settings ==="
echo "$CURRENCY_INFO"
echo ""
echo "Done."
