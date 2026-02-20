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

# SPA fallback + API/WebSocket proxy to backend server
ARG BACKEND_URL=http://server:8081
RUN printf "server {\n\
    listen 8080;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    location /api/ {\n\
        proxy_pass ${BACKEND_URL}/api/;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Upgrade \$http_upgrade;\n\
        proxy_set_header Connection \"upgrade\";\n\
        proxy_set_header Host \$host;\n\
        proxy_set_header X-Real-IP \$remote_addr;\n\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto \$scheme;\n\
        proxy_read_timeout 86400s;\n\
    }\n\
\n\
    location / {\n\
        try_files \$uri \$uri/ /index.html;\n\
    }\n\
}\n" > /etc/nginx/conf.d/default.conf

EXPOSE 8080
