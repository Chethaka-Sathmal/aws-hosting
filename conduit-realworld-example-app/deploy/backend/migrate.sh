#!/usr/bin/env bash
# Runs pending Sequelize migrations against the production database.
#
# Run ONCE per deploy, on ONE instance that already has the new code, before
# rolling the rest of the Auto Scaling group. RDS sits in a private subnet, so
# run it through SSM, for example:
#
#   aws ssm send-command \
#     --instance-ids i-0123456789abcdef0 \
#     --document-name AWS-RunShellScript \
#     --parameters 'commands=["bash /opt/conduit/deploy/backend/migrate.sh"]'
#
# It reuses the service's EnvironmentFile through systemd, so the database
# credentials are parsed exactly as the running API sees them.
set -euo pipefail

APP_DIR="/opt/conduit"
ENV_FILE="/etc/conduit/backend.env"
action="${1:-db:migrate}" # e.g. db:migrate:status

systemd-run \
  --unit "conduit-migrate-$(date +%s)" \
  --uid conduit --gid conduit \
  --property "EnvironmentFile=$ENV_FILE" \
  --working-directory "$APP_DIR/backend" \
  --wait --pipe --collect \
  /usr/local/bin/node "$APP_DIR/node_modules/.bin/sequelize-cli" "$action"
