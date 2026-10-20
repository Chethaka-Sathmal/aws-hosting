#!/usr/bin/env bash
# Packs the backend at the current commit and uploads it for EC2 instances.
#
# Usage (from anywhere in the repo):
#   ARTIFACT_BUCKET=my-conduit-artifacts deploy/backend/package-backend.sh
#
# Produces s3://$ARTIFACT_BUCKET/backend/<git-sha>.tar.gz containing the
# backend source, the workspace package.json/package-lock.json (needed by
# `npm ci -w backend`) and deploy/backend (systemd unit, migrate.sh).
# Only committed files are packed, so node_modules and .env never ship.
#
# Env:
#   ARTIFACT_BUCKET             required, bucket name (no s3:// prefix)
#   AWS_PROFILE / AWS_REGION    optional, standard AWS CLI settings
set -euo pipefail

: "${ARTIFACT_BUCKET:?ARTIFACT_BUCKET is required}"

paths=(backend package.json package-lock.json deploy/backend)

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$app_root"

# The tarball is named after HEAD, so it must contain exactly HEAD
if [[ -n "$(git status --porcelain -- "${paths[@]}")" ]]; then
  echo "Uncommitted changes in: ${paths[*]}" >&2
  echo "Commit or stash them first so the artifact matches its commit." >&2
  exit 1
fi

sha="$(git rev-parse HEAD)"
key="backend/$sha.tar.gz"
# Archive the app directory itself, even when it is a subfolder of the repo
prefix="$(git rev-parse --show-prefix)"
tree="HEAD${prefix:+:${prefix%/}}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tarball="$tmp/backend.tar.gz"

echo "==> Packing $tree"
git -C "$(git rev-parse --show-toplevel)" archive \
  --format=tar.gz -o "$tarball" "$tree" "${paths[@]}"

echo "==> Uploading s3://$ARTIFACT_BUCKET/$key"
aws s3 cp "$tarball" "s3://$ARTIFACT_BUCKET/$key"

echo "==> Done. Set in the launch template's user data:"
echo "ARTIFACT_KEY=\"$key\""
