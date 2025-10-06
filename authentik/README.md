# Authentik - Identity Provider & SSO

Authentik ist eine moderne, open-source Identity Provider (IdP) und Single Sign-On (SSO) Lösung.

## Features

- **OAuth2/OIDC** - Moderne Authentifizierung für Webanwendungen
- **SAML** - Enterprise SSO-Standard
- **LDAP** - Legacy-System-Integration
- **SCIM** - User Provisioning
- **Forward Auth** - Proxy-basierte Authentifizierung
- **Multi-Factor Authentication (MFA)**
- **Conditional Access**
- **Audit Logging**

## Installation

### 1. Voraussetzungen

- Docker und Docker Compose installiert
- Nginx Proxy Manager (oder anderer Reverse Proxy) muss bereits laufen
- Das `proxy_network` muss existieren

### 2. Installation ausführen

```bash
# Im Hauptverzeichnis des Projekts
./install.sh authentik
```

Das Skript wird:
- Verzeichnis `~/authentik-compose` erstellen
- Docker Compose Dateien kopieren
- `.env` aus `example.env` erstellen
- Sichere Secrets automatisch generieren (PostgreSQL Password, Secret Key)

### 3. .env Konfiguration anpassen

Nach der Installation **MUSS** die Datei `~/authentik-compose/.env` angepasst werden:

```bash
nano ~/authentik-compose/.env
```

**Erforderliche Anpassungen:**

#### SMTP Konfiguration (erforderlich)
```bash
AUTHENTIK_EMAIL__HOST=smtp.gmail.com
AUTHENTIK_EMAIL__PORT=587
AUTHENTIK_EMAIL__USERNAME=authentik@orgops.io
AUTHENTIK_EMAIL__PASSWORD=ihr-smtp-passwort
AUTHENTIK_EMAIL__FROM=authentik@orgops.io
AUTHENTIK_EMAIL__USE_TLS=true
```

Die anderen Werte (PostgreSQL Password, Secret Key) wurden bereits automatisch generiert.

### 4. Container starten

Nach Anpassung der .env:

```bash
cd ~/authentik-compose
docker compose up -d
```

### 5. Nginx Proxy Manager konfigurieren

Erstellen Sie einen neuen Proxy Host:

- **Domain Names:** `auth.orgops.io` (Ihre Domain)
- **Scheme:** `http`
- **Forward Hostname/IP:** `authentik_server` oder Server-IP
- **Forward Port:** `9000`
- **Websockets Support:** ✅ Aktiviert
- **SSL:** Let's Encrypt Zertifikat hinzufügen

### 6. Initial Setup

Öffnen Sie `https://auth.orgops.io/if/flow/initial-setup/` und erstellen Sie Ihren Admin-Account.

## Verwendung

### Service-Integration

Nach der Installation können Sie Ihre Services mit Authentik integrieren:

#### OAuth2/OIDC Integration (empfohlen)

1. In Authentik: **Applications** → **Create**
2. Name eingeben, Provider auswählen
3. **Providers** → **Create** → **OAuth2/OpenID Provider**
4. Client ID und Secret notieren
5. Redirect URIs konfigurieren

Unterstützte Services:
- n8n
- Nextcloud
- Ghost (via Plugin)
- GitLab
- Grafana
- Und viele mehr

#### SAML Integration

Für Enterprise-Services wie Mattermost:

1. **Providers** → **Create** → **SAML Provider**
2. ACS URL und Entity ID des Service eintragen
3. Metadata XML herunterladen
4. Im Service importieren

#### LDAP Outpost

Für Legacy-Services (z.B. pfSense, Jellyfin):

1. **Outposts** → **Create**
2. Typ: **LDAP**
3. Provider konfigurieren
4. LDAP Credentials im Service verwenden

#### Forward Auth (für beliebige Webapps)

Schützen Sie beliebige Anwendungen ohne native SSO-Unterstützung:

1. **Providers** → **Create** → **Proxy Provider**
2. External Host konfigurieren
3. Nginx/Traefik für Forward Auth konfigurieren

## Verwaltung

### Logs anzeigen

```bash
cd ~/authentik-compose
docker compose logs -f server
docker compose logs -f worker
```

### Container neu starten

```bash
cd ~/authentik-compose
docker compose restart
```

### Update durchführen

```bash
cd ~/authentik-compose
docker compose pull
docker compose up -d
```

### Backup erstellen

Wichtige Volumes:
- `authentik_database` - PostgreSQL Daten
- `authentik_media` - Uploaded Files, Icons
- `authentik_redis` - Cache (optional)

```bash
docker volume ls | grep authentik
docker run --rm -v authentik_database:/data -v $(pwd):/backup alpine tar czf /backup/authentik-db-backup.tar.gz /data
```

## Sicherheitshinweise

- ✅ Verwenden Sie starke Secrets (werden automatisch generiert)
- ✅ HTTPS ist obligatorisch (über Nginx Proxy Manager)
- ✅ Aktivieren Sie MFA für Admin-Accounts
- ✅ Regelmäßige Backups der PostgreSQL Datenbank
- ✅ Keep Authentik auf dem neuesten Stand

## Troubleshooting

### Container starten nicht

```bash
cd ~/authentik-compose
docker compose logs
```

### E-Mails werden nicht versendet

Prüfen Sie SMTP-Einstellungen in der .env und testen Sie:

```bash
docker compose exec worker ak test_email --to your@email.com
```

### Port 9000 bereits belegt

Ändern Sie in `docker-compose.yml`:
```yaml
ports:
  - "127.0.0.1:9001:9000"  # Anderen Port verwenden
```

### Reset Admin Password

```bash
cd ~/authentik-compose
docker compose exec server ak change_password <username>
```

## Weitere Ressourcen

- **Offizielle Dokumentation:** https://docs.goauthentik.io
- **Integration Guides:** https://docs.goauthentik.io/integrations/
- **GitHub:** https://github.com/goauthentik/authentik
- **Discord Community:** https://discord.gg/jg33eMhnj6

## Konfigurationsdateien

- `docker-compose.yml` - Docker Compose Konfiguration
- `example.env` - Umgebungsvariablen Template
- `generate-secrets.sh` - Secret-Generierung
- `authentik-install.sh` - Installationsskript

## Support

Bei Problemen:
1. Logs prüfen: `docker compose logs -f`
2. Dokumentation konsultieren: https://docs.goauthentik.io
3. GitHub Issues: https://github.com/goauthentik/authentik/issues
