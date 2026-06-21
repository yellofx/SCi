# Secure Dev Environment — Coding-Agent für den öffentlichen Sektor

Eine lokal betreibbare, abgeschottete Entwicklungsumgebung, in der ein
**Open-Source-Coding-Agent** mit **maximaler Freiheit** arbeiten kann
(installieren, bauen, debuggen — z. B. Maven für Java-Apps), während
**sensible Daten die Box nicht verlassen** können. Lokale **und** Remote-Modelle
sind über eine einheitliche API ansprechbar.

## Sicherheitsmodell in einem Satz

> Volle Freiheit **innerhalb** der Sandbox, harte Grenze **am Netzwerk**:
> Egress ausschließlich über einen Allowlist-Proxy. Damit kann der Agent
> bauen/installieren/committen, aber Daten (auch aus `target/`) nicht
> exfiltrieren.

## Architektur

```
Host (deine IDE: IntelliJ / VS Code)
│  öffnet ./sample-app          ── Bind-Mount (Code live editierbar)
│  Remote-Debug → localhost:5005
│  App         → localhost:8080
▼
┌──────────────────────────────────────────────────────────────┐
│  Rootless Podman (compose.yml)                                 │
│                                                                │
│  [dev]   JDK 21 + Maven + Aider/OpenCode, sudo/apt frei        │
│          /workspace        ← Bind-Mount (Quellcode)            │
│          /workspace/target ← internes Volume, NICHT am Host    │
│             nur Netz-Route nach draußen ↓                      │
│  [proxy] Squid, default-deny + Allowlist (Maven/Git/OS/Modell) │
│             │ (einzige Verbindung zum Internet)                │
│  [litellm] eine OpenAI-kompatible API                          │
│  [ollama]  lokales Coder-Modell (Qwen2.5-Coder, …)             │
│                                                                │
│  Netze:  internal (kein NAT)  +  external (nur proxy)          │
└──────────────────────────────────────────────────────────────┘
```

## Wie die Anforderungen erfüllt werden

| Anforderung | Lösung |
|---|---|
| Agent maximal frei (install, debug, mvn) | `dev`-Container mit `sudo`/`apt`, JDK+Maven, JDWP-Port 5005 |
| Lokale IDE sieht/nutzt den Code | `./sample-app` als Bind-Mount; Remote-Debugger an `localhost:5005` |
| Egress erlaubt, aber kontrolliert | Squid-Allowlist; nur Maven/Git/OS/Modell erreichbar |
| Sensible Daten im `target/` | `target/` als container-internes Volume — ephemer, nie am Host, gitignored |
| Secrets nicht im Build | Injection per Env zur Laufzeit → nur Platzhalter in `target/classes` |
| Keine Echtdaten in Dev | synthetische Daten (`citizens.synthetic.json`) |
| Lokal **und** Remote Modelle | LiteLLM-Gateway, Backend per Config umschaltbar |

## Schnellstart

```bash
cd secure-dev-env
cp .env.example .env          # Secrets eintragen (bleibt gitignored)
./scripts/up.sh               # baut & startet alles, zieht lokales Modell
./scripts/agent.sh aider      # Coding-Agent betreten (oder: opencode | shell)
```

In der **lokalen IDE**: Ordner `secure-dev-env/sample-app` öffnen, dann einen
*Remote JVM Debug* auf `localhost:5005`. App testen:

```bash
curl http://localhost:8080/citizens
```

App im Container mit Debug starten:

```bash
podman exec -it sde-dev bash -lc \
  'mvn -q spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"'
```

Abbauen (mit `-v` auch das ephemere `target/`-Volume verwerfen):

```bash
./scripts/down.sh -v
```

## Modell wechseln (lokal ↔ remote)

Alles läuft über `http://litellm:4000`. In `litellm/config.yaml`:

- **lokal (Default):** `local-coder` → Ollama (`qwen2.5-coder:7b`). Voll souverän.
- **remote:** `remote-coder` auf einen EU-/souveränen OpenAI-kompatiblen Endpoint
  zeigen lassen — Host **muss** zusätzlich in `proxy/squid.conf` allowlisted werden.

Im Agenten einfach das Modell tauschen (`--model openai/remote-coder`); der Agent
selbst kennt den Unterschied nicht.

## Den „target/"-Leak verstehen

`target/` ist nur **Wegwerf-Output**. Geschützt wird auf drei Ebenen:

1. **`target/` ist ephemer** — internes Volume, nie am Host, gitignored.
2. **Secrets fließen nicht hinein** — Env-Injection zur Laufzeit statt im Repo.
3. **Selbst wenn sensible Daten hineingelangen** — der Allowlist-Egress
   verhindert, dass sie die Box verlassen.

→ Nicht das `target/` verstecken, sondern (1) verhindern dass Sensibles
hineinkommt und (2) verhindern dass es hinausgeht.

## Härtungs-Backlog (Produktion)

- MicroVM (Firecracker/Kata) statt Container, falls der Agent Kernel-nahen
  Code / Docker-in-Docker braucht.
- DLP/Redaction im Proxy bzw. `turn_off_message_logging` in LiteLLM.
- Audit-Log aller Prompts/Responses (Nachvollziehbarkeit).
- Eigener Nexus/Artifactory statt Maven Central in der Allowlist.
- Signierte Images, read-only Rootfs, seccomp/AppArmor-Profile.
