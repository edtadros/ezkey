#!/bin/zsh
# Scan tracked files for live secrets and personal data.
# Public identity edtadros and hello@ezkey.app are allowed.
# Exit 0 when the tracked tree is clean.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

fail=0
report() {
  echo "HIT $1"
  fail=1
}

while IFS= read -r path; do
  case "$path" in
    *.pem|*.p12|*.p8|*.key|*.mobileprovision|.env|.env.*|*credentials*.json|service-account*.json)
      report "filename $path"
      ;;
  esac
done < <(git ls-files)

scan_lines() {
  local label="$1"
  local pattern="$2"
  local line
  if git grep -nI -E "$pattern" -- . >"$3" 2>/dev/null; then
    while IFS= read -r line; do
      if [[ "$label" == "email" && "$line" == *"hello@ezkey.app"* ]]; then
        continue
      fi
      report "$label $line"
    done < "$3"
  fi
}

workdir="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$workdir"' EXIT

scan_lines secret 'BEGIN (RSA |OPENSSH |EC |DSA |PRIVATE )PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk_live_[A-Za-z0-9]{8,}|sk_test_[A-Za-z0-9]{16,}' "$workdir/secrets"
scan_lines email '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.(com|net|org|app|io|dev|me)' "$workdir/emails"
scan_lines phone '(^|[^0-9])(\+1[\s.-]?)?\(?[0-9]{3}\)?[\s.-][0-9]{3}[\s.-][0-9]{4}([^0-9]|$)' "$workdir/phones"
scan_lines address '[0-9]{1,6} [A-Za-z0-9.'\''-]+ (Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd)\.?' "$workdir/streets"

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
echo "clean: no secrets or personal data in tracked files"
