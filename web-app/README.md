# Web-App Deployment-Hülle

Eine generische Docker-Compose-basierte Deployment-Lösung für Web-Anwendungen, die nahtlos mit dem Nginx Proxy Manager zusammenarbeitet.

## 🎯 Überblick

Diese Deployment-Hülle ermöglicht es Ihnen, beliebige Web-Anwendungen (Nuxt, Next.js, React, Vue, etc.) auf Ihrem Server zu deployen, ohne die Entwicklungsstruktur Ihrer Apps anzupassen. Entwickeln Sie Ihre Apps völlig losgelöst und deployen Sie sie mit wenigen Befehlen auf Ihrem Server.

## ✨ Features

- 🚀 Framework-agnostisch (Nuxt, Next.js, React, Vue, Svelte, Express, etc.)
- 🐳 Docker-basiert für einfache Verwaltung
- 🔌 Automatische Integration mit Nginx Proxy Manager
- 🔒 Externes `proxy_network` für sichere Kommunikation
- 📦 Unterstützung für mehrere Apps parallel
- 🔄 Einfache Updates via Git
- 🌍 Umgebungsvariablen über `.env` Dateien

## 📋 Voraussetzungen

- Docker und Docker Compose installiert
- Nginx Proxy Manager installiert und konfiguriert (`./install.sh npm`)
- Das externe Docker-Netzwerk `proxy_network` muss existieren

## 🚀 Schnellstart

### 1. Neue App deployen

```bash
# Deployment-Hülle erstellen
./install.sh webapp meine-app

# In das erstellte Verzeichnis wechseln
cd ~/web-apps/meine-app

# .env anpassen
nano .env
```

### 2. .env konfigurieren

Passen Sie mindestens folgende Werte an:

```bash
SUBDOMAIN=meine-app           # Subdomain für Ihre App
DOMAIN_NAME=example.com       # Ihre Domain
APP_PORT=3000                 # Port auf dem Ihre App läuft
```

### 3. Ihre App klonen

```bash
# Klonen Sie Ihre App ins app/ Verzeichnis
git clone https://github.com/user/meine-app.git app

# Wichtig: Ihre App muss ein Dockerfile im Root-Verzeichnis enthalten!
```

### 4. App starten

```bash
docker compose up -d
```

### 5. Nginx Proxy Manager konfigurieren

1. Öffnen Sie die NPM Admin-Oberfläche (normalerweise auf Port 81)
2. Erstellen Sie einen neuen **Proxy Host**:
   - **Domain Names**: `meine-app.example.com` (Ihre Subdomain + Domain)
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `web-app-meine-app` (Container-Name)
   - **Forward Port**: `3000` (oder Ihr APP_PORT aus .env)
   - **SSL**: Aktivieren und Let's Encrypt Zertifikat anfordern

Ihre App ist jetzt unter `https://meine-app.example.com` erreichbar! 🎉

## 📁 Verzeichnisstruktur

Nach der Installation wird folgende Struktur erstellt:

```
~/web-apps/meine-app/
├── docker-compose.yml        # Docker Compose Konfiguration
├── .env                      # Umgebungsvariablen
├── Dockerfile.example        # Beispiel-Dockerfiles als Referenz
└── app/                      # Ihre geklonte App (Git Repository)
    ├── Dockerfile            # Ihr App-spezifisches Dockerfile
    ├── package.json
    └── ... (Ihre App-Dateien)
```

## 🐳 Dockerfile-Anforderungen

Ihre App muss ein `Dockerfile` im Root-Verzeichnis enthalten. Siehe `Dockerfile.example` für verschiedene Framework-Beispiele:

### Beispiel: Nuxt 3 App

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.output /app/.output
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev
EXPOSE 3000
ENV HOST=0.0.0.0
ENV PORT=3000
CMD ["node", ".output/server/index.mjs"]
```

### Beispiel: Next.js App

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
```

Weitere Beispiele finden Sie in der `Dockerfile.example` Datei.

## 🔧 Verwaltungskommandos

### App-Logs anzeigen
```bash
cd ~/web-apps/meine-app
docker compose logs -f
```

### App aktualisieren
```bash
cd ~/web-apps/meine-app
git -C app pull
docker compose up -d --build
```

### App neu bauen
```bash
cd ~/web-apps/meine-app
docker compose up -d --build
```

### App stoppen
```bash
cd ~/web-apps/meine-app
docker compose down
```

### App entfernen
```bash
cd ~/web-apps/meine-app
docker compose down
cd ~
rm -rf ~/web-apps/meine-app
```

## 🌍 Umgebungsvariablen

Die `.env` Datei kann beliebige Umgebungsvariablen enthalten, die an Ihre App weitergereicht werden:

```bash
# Standard-Variablen
APP_NAME=meine-app
SUBDOMAIN=meine-app
DOMAIN_NAME=example.com
APP_PORT=3000
NODE_ENV=production

# Ihre benutzerdefinierten Variablen
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=your_api_key_here
REDIS_URL=redis://redis:6379
JWT_SECRET=your_secret_here
```

Alle Variablen aus `.env` werden automatisch an Ihren Container übergeben.

## 🔄 Mehrere Apps parallel

Sie können beliebig viele Apps parallel deployen:

```bash
./install.sh webapp shop
./install.sh webapp blog
./install.sh webapp dashboard
./install.sh webapp api
```

Jede App läuft in ihrem eigenen Container und hat ihre eigene Konfiguration:
- `~/web-apps/shop` → Container: `web-app-shop`
- `~/web-apps/blog` → Container: `web-app-blog`
- `~/web-apps/dashboard` → Container: `web-app-dashboard`
- `~/web-apps/api` → Container: `web-app-api`

## 🛠️ Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
docker compose logs

# Container-Status prüfen
docker compose ps
```

### App nicht erreichbar

1. Prüfen Sie ob der Container läuft: `docker compose ps`
2. Prüfen Sie die NPM Proxy Host Konfiguration
3. Stellen Sie sicher, dass DNS A-Record korrekt gesetzt ist
4. Prüfen Sie ob APP_PORT korrekt ist: `docker compose logs`

### Build schlägt fehl

1. Prüfen Sie ob das Dockerfile in `app/` existiert
2. Prüfen Sie Dockerfile-Syntax
3. Bauen Sie manuell: `docker compose build --no-cache`

### Port-Konflikte

Ändern Sie APP_PORT in der `.env` und bauen Sie neu:
```bash
nano .env  # APP_PORT=3001 statt 3000
docker compose up -d --build
```

## 💡 Best Practices

1. **Umgebungsvariablen**: Nutzen Sie `.env` für alle konfigurierbaren Werte
2. **Multi-Stage Builds**: Verwenden Sie Multi-Stage Builds für kleinere Images
3. **Git**: Committen Sie niemals `.env` Dateien in Ihr Repository
4. **Backups**: Sichern Sie regelmäßig Ihre `.env` Dateien
5. **Updates**: Automatisieren Sie Updates mit Cron-Jobs
6. **Logs**: Überwachen Sie regelmäßig die Container-Logs
7. **Resources**: Setzen Sie bei Bedarf Resource-Limits in `docker-compose.yml`

## 📚 Weiterführende Ressourcen

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Proxy Manager Documentation](https://nginxproxymanager.com/guide/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Support

Bei Problemen oder Fragen:
1. Prüfen Sie die Logs: `docker compose logs`
2. Überprüfen Sie die Konfiguration: `cat .env`
3. Stellen Sie sicher, dass NPM läuft: `docker ps | grep nginx-proxy-manager`

## 📝 Lizenz

Diese Deployment-Hülle ist Teil des OrgOps Tool-Configurations Projekts.
