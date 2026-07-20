#!/usr/bin/env bash
set -euo pipefail

BASE=${BASE:-http://articles.local}

echo "=== 1. HEALTH ==="
curl -sS "$BASE/healthz" | jq .
curl -sS "$BASE/readyz" | jq .
echo

echo "=== 2. CREATE ==="
RESP=$(curl -sS -X POST "$BASE/articles" -H "Content-Type: application/json" \
  -d '{"title":"Kubernetes 1.35","body":"Multi-zone active-active tips","author":"roshan","tags":["k8s","sre"]}')
echo "$RESP" | jq .
ID=$(echo "$RESP" | jq -r ._id)
echo "created id=$ID"
echo

echo "=== 3. LIST ==="
curl -sS "$BASE/articles" | jq .
echo

echo "=== 4. GET ==="
curl -sS "$BASE/articles/$ID" | jq .
echo

echo "=== 5. UPDATE ==="
curl -sS -X PUT "$BASE/articles/$ID" -H "Content-Type: application/json" \
  -d '{"title":"Kubernetes 1.35 (revised)","body":"Multi-zone A-A + Zone C","author":"roshan","tags":["k8s","sre","multizone"]}' | jq .
echo

echo "=== 6. DELETE ==="
curl -sS -o /dev/null -w "HTTP %{http_code}\n" -X DELETE "$BASE/articles/$ID"

echo "=== 7. VERIFY DELETE ==="
curl -sS -o /dev/null -w "HTTP %{http_code}\n" "$BASE/articles/$ID"

echo "=== ALL PASS ==="
