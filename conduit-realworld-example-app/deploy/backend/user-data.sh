#!/usr/bin/env bash
# EC2 user-data for the Conduit backend Auto Scaling group (Amazon Linux 2023).
#
# Paste into the launch template's user data after setting the variables below.
# Each instance boots, installs Node, downloads the backend artifact built by
# deploy/backend/package-backend.sh, installs backend dependencies, pulls
# config from SSM Parameter Store and starts the API.
#
# Database migrations are deliberately NOT run here; run them once per deploy
# with deploy/backend/migrate.sh (see README).
#
# Instance role needs: AmazonSSMManagedInstanceCore, s3:GetObject on
# ARTIFACT_BUCKET/backend/*, ssm:GetParametersByPath on the SSM_PREFIX path,
# and kms:Decrypt for the key encrypting SecureStrings.
set -euo pipefail

ARTIFACT_BUCKET="my-conduit-artifacts"
ARTIFACT_KEY="backend/<git-sha>.tar.gz"
SSM_PREFIX="/conduit/prod"
NODE_VERSION="22.23.1"
APP_DIR="/opt/conduit"
ENV_FILE="/etc/conduit/backend.env"

exec > >(tee -a /var/log/conduit-user-data.log) 2>&1

echo "==> Installing packages"
dnf install -y tar xz gzip

imds_token="$(curl -fsS -X PUT http://169.254.169.254/latest/api/token \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")"
region="$(curl -fsS -H "X-aws-ec2-metadata-token: $imds_token" \
  http://169.254.169.254/latest/meta-data/placement/region)"

echo "==> Installing Node.js $NODE_VERSION"
case "$(uname -m)" in
  x86_64) node_arch="x64" ;;
  aarch64) node_arch="arm64" ;;
  *) echo "Unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac
node_tar="node-v$NODE_VERSION-linux-$node_arch.tar.xz"
tmp="$(mktemp -d)"
curl -fsSL -o "$tmp/$node_tar" "https://nodejs.org/dist/v$NODE_VERSION/$node_tar"
curl -fsSL -o "$tmp/SHASUMS256.txt" "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt"
(cd "$tmp" && grep " $node_tar\$" SHASUMS256.txt | sha256sum -c -)
tar -xJf "$tmp/$node_tar" -C /usr/local --strip-components=1 \
  --exclude CHANGELOG.md --exclude LICENSE --exclude README.md
rm -rf "$tmp"
node --version

echo "==> Creating service user"
id conduit &>/dev/null || useradd --system --create-home --shell /sbin/nologin conduit

echo "==> Downloading s3://$ARTIFACT_BUCKET/$ARTIFACT_KEY"
artifact="$(mktemp)"
aws s3 cp --region "$region" "s3://$ARTIFACT_BUCKET/$ARTIFACT_KEY" "$artifact"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
tar -xzf "$artifact" -C "$APP_DIR"
rm -f "$artifact"
chown -R conduit:conduit "$APP_DIR"

echo "==> Installing backend dependencies"
# The lockfile lives at the workspace root, so install from there
sudo -u conduit -H bash -c "cd '$APP_DIR' && npm ci --omit=dev -w backend"

echo "==> Writing $ENV_FILE from SSM $SSM_PREFIX"
install -d -m 750 -o root -g conduit "$(dirname "$ENV_FILE")"
env_tmp="$(mktemp)"
{
  echo "NODE_ENV=production"
  echo "PORT=3001"
  # Parameter names map to variable names: $SSM_PREFIX/JWT_KEY -> JWT_KEY
  aws ssm get-parameters-by-path \
    --region "$region" \
    --path "$SSM_PREFIX" \
    --recursive \
    --with-decryption \
    --query "Parameters[].[Name,Value]" \
    --output text |
    while IFS=$'\t' read -r name value; do
      value="${value//\\/\\\\}"
      value="${value//\"/\\\"}"
      printf '%s="%s"\n' "${name##*/}" "$value"
    done
} > "$env_tmp"
install -m 640 -o root -g conduit "$env_tmp" "$ENV_FILE"
rm -f "$env_tmp"

echo "==> Starting conduit-backend"
install -m 644 "$APP_DIR/deploy/backend/conduit-backend.service" \
  /etc/systemd/system/conduit-backend.service
systemctl daemon-reload
systemctl enable --now conduit-backend

echo "==> Waiting for health check"
for _ in $(seq 1 30); do
  if curl -fsS http://localhost:3001/health; then
    echo
    echo "==> Done"
    exit 0
  fi
  sleep 2
done
echo "Backend did not become healthy; see: journalctl -u conduit-backend" >&2
exit 1
