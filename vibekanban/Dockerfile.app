FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable

# Copy workspace config and lockfile from cloned repo
COPY vibe-kanban/pnpm-workspace.yaml vibe-kanban/pnpm-lock.yaml vibe-kanban/package.json ./
COPY vibe-kanban/frontend/package.json ./frontend/
COPY vibe-kanban/shared/ ./shared/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy frontend source
COPY vibe-kanban/frontend/ ./frontend/

# Build with API base URL baked in
ARG VITE_VK_SHARED_API_BASE
ENV VITE_VK_SHARED_API_BASE=${VITE_VK_SHARED_API_BASE}

RUN pnpm -C frontend build

# Serve with nginx
FROM nginx:alpine

COPY --from=builder /app/frontend/dist /usr/share/nginx/html

# SPA fallback - all routes to index.html
RUN printf 'server {\n\
    listen 3000;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 3000
