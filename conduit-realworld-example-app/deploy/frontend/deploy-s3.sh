#!/usr/bin/env bash
# Builds the frontend and publishes it to the S3 origin behind CloudFront.
#
# Usage (from anywhere in the repo):
#   S3_BUCKET=my-conduit-frontend \
#   CLOUDFRONT_DISTRIBUTION_ID=E123ABC \
#   deploy/frontend/deploy-s3.sh
#
# Env:
#   S3_BUCKET                   required, bucket name (no s3:// prefix)
#   CLOUDFRONT_DISTRIBUTION_ID  optional, invalidates index.html after upload
#   VITE_API_URL                optional, leave unset to use same-origin /api/*
#   AWS_PROFILE / AWS_REGION    optional, standard AWS CLI settings
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dist="$repo_root/frontend/dist"

cd "$repo_root"
echo "==> Installing dependencies"
npm ci
echo "==> Building frontend (VITE_API_URL='${VITE_API_URL:-}')"
npm run build -w frontend

# Hashed bundles never change, so cache them for a year. Everything else
# (index.html, favicons, manifest) must be revalidated so new deploys show up.
echo "==> Uploading hashed assets"
aws s3 sync "$dist/assets" "s3://$S3_BUCKET/assets" \
  --delete \
  --cache-control "public,max-age=31536000,immutable"

echo "==> Uploading remaining files"
aws s3 sync "$dist" "s3://$S3_BUCKET" \
  --delete \
  --exclude "assets/*" \
  --cache-control "no-cache"

if [[ -n "${CLOUDFRONT_DISTRIBUTION_ID:-}" ]]; then
  echo "==> Invalidating CloudFront cache"
  aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --paths "/" "/index.html" \
    --query "Invalidation.Id" --output text
fi

echo "==> Done"
