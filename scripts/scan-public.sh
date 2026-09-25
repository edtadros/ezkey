#!/usr/bin/env bash
# Scan tracked files for live secrets and personal data.
# Public identity edtadros and hello@ezkey.app are allowed.
# Extra files passed after --extra are classified with the same rules
# and are not required to be tracked.
# Exit 0 when nothing is flagged.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

fail=0
report() {
  echo "HIT $1"
  fail=1
}

email_re='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.(com|net|org|app|io|dev|me)'
secret_re='BEGIN (RSA |OPENSSH |EC |DSA |PRIVATE )PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk_live_[A-Za-z0-9]{8,}|sk_test_[A-Za-z0-9]{16,}|sk-proj-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9_-]{32,}'
phone_re='(^|[^0-9])(\+1[[:space:].-]?)?\(?[0-9]{3}\)?[[:space:].-][0-9]{3}[[:space:].-][0-9]{4}([^0-9]|$)'
street_re='[0-9]{1,6} [A-Za-z0-9.'\''-]+ (Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd)\.?'

classify_email_line() {
  local line="$1"
  local addr
  local bad=0
  while IFS= read -r addr; do
    [[ -z "$addr" ]] && continue
    if [[ "$addr" != "hello@ezkey.app" ]]; then
      bad=1
    fi
  done < <(printf '%s\n' "$line" | grep -oE "$email_re" || true)
  if [[ "$bad" -eq 1 ]]; then
    report "email $line"
  fi
}

scan_text_file() {
  local file="$1"
  local line
  if grep -nI -E "$secret_re" "$file" >"$workdir/sec" 2>/dev/null; then
    while IFS= read -r line; do
      report "secret $file:$line"
    done <"$workdir/sec"
  fi
  if grep -nI -E "$email_re" "$file" >"$workdir/em" 2>/dev/null; then
    while IFS= read -r line; do
      classify_email_line "$file:$line"
    done <"$workdir/em"
  fi
  if grep -nI -E "$phone_re" "$file" >"$workdir/ph" 2>/dev/null; then
    while IFS= read -r line; do
      report "phone $file:$line"
    done <"$workdir/ph"
  fi
  if grep -nI -E "$street_re" "$file" >"$workdir/st" 2>/dev/null; then
    while IFS= read -r line; do
      report "address $file:$line"
    done <"$workdir/st"
  fi
}

while IFS= read -r path; do
  case "$path" in
    *.pem|*.p12|*.p8|*.key|*.mobileprovision|.env|.env.*|*.env|*credentials*.json|service-account*.json|id_rsa|id_dsa|id_ecdsa|id_ed25519|.netrc)
      report "filename $path"
      ;;
  esac
done < <(git ls-files)

workdir="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$workdir"' EXIT

if git grep -nI -E "$secret_re" -- . >"$workdir/secrets" 2>/dev/null; then
  while IFS= read -r line; do
    report "secret $line"
  done <"$workdir/secrets"
fi

if git grep -nI -E "$email_re" -- . >"$workdir/emails" 2>/dev/null; then
  while IFS= read -r line; do
    classify_email_line "$line"
  done <"$workdir/emails"
fi

if git grep -nI -E "$phone_re" -- . >"$workdir/phones" 2>/dev/null; then
  while IFS= read -r line; do
    report "phone $line"
  done <"$workdir/phones"
fi

if git grep -nI -E "$street_re" -- . >"$workdir/streets" 2>/dev/null; then
  while IFS= read -r line; do
    report "address $line"
  done <"$workdir/streets"
fi

extra=0
for arg in "$@"; do
  if [[ "$arg" == "--extra" ]]; then
    extra=1
    continue
  fi
  if [[ "$extra" -eq 1 ]]; then
    scan_text_file "$arg"
  fi
done

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
echo "clean: no secrets or personal data in tracked files"
