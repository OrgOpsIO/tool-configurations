# RunPod Serverless GPU einrichten

Kein SSH, kein Terminal im Pod. Alles über das RunPod-UI.

---

## Was ist RunPod Serverless?

Ein verwalteter Endpoint-Service: Du konfigurierst einmal Modell + GPU-Typ,
bekommst eine permanente URL, und trägst diese in die `.env` ein.
RunPod startet den GPU-Worker automatisch wenn Anfragen kommen (Cold Start ~30s)
und fährt ihn bei Inaktivität wieder herunter. Du zahlst nur für tatsächliche Nutzung.

---

## Einmalige Einrichtung (ca. 5 Minuten)

### Schritt 1 — RunPod-Account

- runpod.io → Account erstellen
- Guthaben aufladen (Kreditkarte, min. $10)

### Schritt 2 — API Key erstellen

**Settings → API Keys → + API Key**

Den Key sofort kopieren — er wird nur einmal angezeigt.

### Schritt 3 — Serverless Endpoint erstellen

1. Im Menü: **Serverless → + New Endpoint**
2. Suchfeld: `vllm` eingeben → **RunPod vLLM Worker** auswählen
3. Konfigurieren:

   | Feld            | Empfehlung                              |
   |-----------------|----------------------------------------|
   | Name            | `vllm-gpu`                             |
   | GPU             | RTX 4090 (24 GB) oder L40S (48 GB)     |
   | Min Workers     | `0` (startet nur bei Bedarf → kostenlos wenn idle) |
   | Max Workers     | `1`                                    |
   | Idle Timeout    | `5` Minuten                            |
   | Environment Variable `MODEL_NAME` | HuggingFace Model ID (s.u.) |

4. **Deploy**

### Modell wählen

| Modell                              | VRAM  | GPU-Empfehlung   |
|-------------------------------------|-------|------------------|
| `Qwen/Qwen2.5-14B-Instruct`        | 10 GB | RTX 4090 (24 GB) |
| `Qwen/Qwen2.5-32B-Instruct`        | 20 GB | RTX 4090 (24 GB) |
| `meta-llama/Llama-3.3-70B-Instruct`| 45 GB | L40S (48 GB)     |

Für Llama: `HF_TOKEN` ebenfalls als Environment Variable eintragen
(Token mit Modell-Zugriff von huggingface.co/settings/tokens).

### Schritt 4 — Endpoint ID ablesen

Nach dem Deployment steht die **Endpoint ID** in der Übersicht:
```
Endpoint ID: abc123xyz
```

Die fertige URL ist immer:
```
https://api.runpod.ai/v2/<endpoint-id>/openai/v1
```

---

## In den Stack eintragen

In der `.env` des vllm-Stacks:

```env
RUNPOD_ENDPOINT_URL=https://api.runpod.ai/v2/<endpoint-id>/openai/v1
RUNPOD_API_KEY=<dein-runpod-api-key>
```

Dann OpenWebUI neu starten:

```bash
docker compose restart openwebui
```

Das GPU-Modell erscheint jetzt automatisch im Modell-Selector neben dem lokalen CPU-Modell.
Cold Start beim ersten Request: ~30 Sekunden. Danach normal schnell.

---

## Kosten

Da Min Workers = 0: **Keine Grundkosten.** Nur Abrechnung pro verarbeiteter Sekunde.

| GPU       | Preis/Sekunde | 1h aktive Nutzung |
|-----------|---------------|-------------------|
| RTX 4090  | ~$0,00019     | ~$0,69            |
| L40S      | ~$0,00053     | ~$1,90            |

Idle-Zeit (kein Request) kostet nichts.

---

## Modell wechseln

Im RunPod-UI: **Serverless → Endpoint → Edit → Environment Variables → MODEL_NAME** ändern → Save.
Kein Neustart des lokalen Stacks nötig.

---

## Endpoint deaktivieren

Im RunPod-UI: **Serverless → Endpoint → Delete** (oder einfach stehen lassen bei Min Workers = 0 — es entstehen keine Kosten).
