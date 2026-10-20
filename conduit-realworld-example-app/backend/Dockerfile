# Conduit backend API image.
# Build from the repository root, because the lockfile is workspace-level:
#   docker build -f backend/Dockerfile -t conduit-backend .
FROM node:22.23.1-bookworm-slim

ENV NODE_ENV=production
WORKDIR /app

# Install production dependencies first so this layer is cached between code
# changes. bcrypt ships prebuilt glibc binaries, so no build tools are needed.
COPY package.json package-lock.json ./
COPY backend/package.json backend/
RUN npm ci --omit=dev -w backend \
  && npm cache clean --force

COPY backend/ backend/

# Files stay root-owned and read-only to the app; run as the image's
# unprivileged "node" user.
USER node
WORKDIR /app/backend
EXPOSE 3001

# Migrations reuse this image with a command override:
#   node /app/node_modules/.bin/sequelize-cli db:migrate
CMD ["node", "index.js"]
