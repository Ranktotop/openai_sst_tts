# Qwen3-TTS Setup für Open Notebook

## Schnellstart

### 1. Repository klonen

```bash
git clone https://github.com/QwenLM/Qwen3-TTS.git
cd Qwen3-TTS
```

### 2. Docker Compose starten

```bash
# GPU-Version (empfohlen)
docker-compose up qwen3-tts-gpu -d

# Oder mit meiner optimierten docker-compose.yml:
# Kopiere die Datei ins Repo und starte:
docker-compose up -d
```

### 3. Warten bis Modell geladen

```bash
# Logs beobachten (erster Start lädt ~8GB Modell)
docker-compose logs -f

# Oder Health-Check:
curl http://localhost:8880/health
```

### 4. Testen

```bash
# Deutsche Sprachausgabe
curl -X POST http://localhost:8880/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tts-1-de",
    "voice": "Vivian",
    "input": "Hallo! Dies ist ein Test."
  }' --output test.mp3
```

---

## Open Notebook Konfiguration

In Open Notebook die TTS-Einstellungen anpassen:

| Einstellung      | Wert                       |
| ---------------- | -------------------------- |
| **TTS Provider** | OpenAI-kompatibel          |
| **API URL**      | `http://localhost:8880/v1` |
| **API Key**      | `not-needed` (beliebig)    |
| **Model**        | `tts-1-de` (für Deutsch)   |
| **Voice**        | `Vivian` oder `Ryan`       |

---

## Hardware-Anforderungen

| Modell                            | VRAM     | Qualität |
| --------------------------------- | -------- | -------- |
| `Qwen3-TTS-12Hz-0.6B-CustomVoice` | ~4-6 GB  | Gut      |
| `Qwen3-TTS-12Hz-1.7B-CustomVoice` | ~8-12 GB | Beste    |

### Für weniger VRAM (0.6B Modell):

```yaml
environment:
  - TTS_MODEL_NAME=Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice
```

---

## Verfügbare Stimmen

| Stimme       | Beschreibung              | Beste Sprache |
| ------------ | ------------------------- | ------------- |
| **Vivian**   | Hell, jung, weiblich      | Chinesisch    |
| **Serena**   | Warm, sanft, weiblich     | Chinesisch    |
| **Ryan**     | Dynamisch, männlich       | Englisch      |
| **Aiden**    | Sonnig, amerikanisch      | Englisch      |
| **Dylan**    | Beijing-Dialekt, männlich | Chinesisch    |
| **Eric**     | Sichuan-Dialekt, männlich | Chinesisch    |
| **Uncle_Fu** | Tief, männlich, älter     | Chinesisch    |
| **Ono_Anna** | Verspielt, weiblich       | Japanisch     |
| **Sohee**    | Warm, emotional           | Koreanisch    |

> **Hinweis:** Alle Stimmen können alle 10 Sprachen sprechen, aber die native Sprache klingt am besten.

---

## Sprach-Codes

Für deutsches TTS immer `tts-1-de` als Model verwenden:

```python
response = client.audio.speech.create(
    model="tts-1-de",      # Erzwingt deutsche Aussprache
    voice="Vivian",
    input="Guten Tag!"
)
```

| Code       | Sprache       |
| ---------- | ------------- |
| `tts-1-de` | Deutsch       |
| `tts-1-en` | Englisch      |
| `tts-1-fr` | Französisch   |
| `tts-1-es` | Spanisch      |
| `tts-1-it` | Italienisch   |
| `tts-1-pt` | Portugiesisch |
| `tts-1-ru` | Russisch      |
| `tts-1-zh` | Chinesisch    |
| `tts-1-ja` | Japanisch     |
| `tts-1-ko` | Koreanisch    |

---

## Troubleshooting

### Container startet nicht

```bash
# NVIDIA Docker Runtime prüfen
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### Langsame erste Anfrage

- Normal! Beim ersten Start wird das Modell (~8GB) heruntergeladen
- Setze `TTS_WARMUP_ON_START=true` für schnellere erste Requests

### Out of Memory

- Wechsle zum kleineren 0.6B Modell
- Oder reduziere die Textlänge pro Request

---

## Performance

| Backend                      | RTF\* | Empfehlung           |
| ---------------------------- | ----- | -------------------- |
| Official + Flash Attention 2 | 0.87  | ✅ Beste Wahl        |
| vLLM-Omni                    | 0.83  | Schneller, komplexer |

\*RTF = Real-Time Factor (< 1.0 = schneller als Echtzeit)

---

## Links

- [Qwen3-TTS GitHub](https://github.com/QwenLM/Qwen3-TTS)
- [Hugging Face Models](https://huggingface.co/collections/Qwen/qwen3-tts)
- [Paper](https://arxiv.org/abs/2601.15621)
