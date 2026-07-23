# ChainForge Open OnDemand app — deployment notes

A Batch Connect interactive app for [ChainForge](https://chainforge.ai/), built to match
the conventions of the other Vulcan interactive apps (shared `templates/job_params`,
`CustomClusterInfo` initializers, OIDC email file, shared `form.js`).

## What it does

- Submits an interactive job to **`gpubase_interac`** (same partition as the other apps),
  no `--gres` (ChainForge only calls external LLM APIs — no GPU). The launch form mirrors the
  other apps (shared `job_params` + `form_params_cpu_app`), **CPU-only**, defaulting to
  **4 cores / 4 GB** with both enforced as minimums (can't go lower). Users choose runtime via
  "Number of hours".
- Installs ChainForge on demand into `$SCRATCH/chainforge/sysvenv` on first launch (on the
  compute node), reused on every node thereafter. Launches `chainforge serve` and OOD
  reverse-proxies it under `/rnode/<host>/<port>/`.

## Why this Python (important)

ChainForge hard-depends on `markitdown[docx,pdf,pptx,xls,xlsx]`, which pins
**`Pillow>=12.2.0`**, **`pypdfium2>=5.9.0`**, and pulls `onnxruntime`/`magika`/`cryptography`.
None of those exist as compatible wheels in the Alliance wheelhouse at those versions, so a
default install against the **CVMFS Python** tries to build them from source and runs out of
memory. Worse: the CVMFS Gentoo Python **does not emit `manylinux` tags**, so pip refuses
PyPI's prebuilt wheels for these too (e.g. `cryptography ... from versions: none`).

The fix used here: **bypass CVMFS** and build the venv from the **OS Python `/usr/bin/python3`
(3.12)**, which emits manylinux tags and pulls all those packages as wheels straight from PyPI.
`script.sh.erb` does `module --force purge`, puts `/usr/bin` first on PATH, and uses
`/usr/bin/python3 -m venv`. Verified: clean install, peak RSS ~840 MB, no source builds.

## Install / redeploy

```bash
sudo rm -rf /var/www/ood/apps/sys/chainforge_app
sudo cp -r ~/chainforge_app /var/www/ood/apps/sys/chainforge_app
sudo chown -R root:root /var/www/ood/apps/sys/chainforge_app
sudo chmod +x /var/www/ood/apps/sys/chainforge_app/template/*.erb
```

No restart needed — OOD discovers `sys` apps automatically. Launch a **new** session to pick
up changes (don't reuse an old one).

## First-launch behaviour

~2–3 min extra while pip installs chainforge + wheels into the venv (watch the session's
`output.log`). If a venv already exists at `$SCRATCH/chainforge/sysvenv` it is reused (instant).

## Reverse proxy

ChainForge is a Flask app with a Create-React-App frontend. CRA bakes absolute
`/static/...` asset tags, and — critically — the bundle **hardcodes its API base to `/`**
(it computes `_f = "/"` whenever `window.__CF_HOSTNAME`/`__CF_PORT` are set). Under OOD's
`/rnode/<host>/<port>/` proxy that makes the browser send every API call to the document
*root*, where the OOD dashboard answers with HTML (`<!DOCTYPE`) or `405` instead of the
Flask API — so through the UI you could not save flows, upload files, or see the Vulcan
provider, even though the backend itself was healthy. Verified direct-to-backend on the
running job: `PUT /api/flows/x.cforge` with a real `flow` body returns `200` and writes the
file; `POST /app/loadCachedCustomProviders` returns the Vulcan provider with all 24 chat
models. The flows dir resolves correctly to `~/.local/share/chainforge` (writable, holds
`provider_scripts/vulcan_provider.py` + `vulcan_models.json`). The problem was purely that
the browser never reached those routes through the proxy.

`script.sh.erb` therefore applies **two** idempotent patches to the built `index.html`:

1. **Relative assets** — `/static/...` → `./static/...` (CRA's auto-publicPath re-bases the
   code-split chunks from the script URL).
2. **API base rewriter** — injects a tiny `<script>` just before `</head>` that rewrites
   absolute-path `XMLHttpRequest`/`fetch` URLs to the `/rnode/<host>/<port>/` mount so API
   calls actually reach Flask. (It must sit before `</head>`, not right after `<head>`:
   `flask_app` re-injects the `__CF_HOSTNAME` script at byte 60 on every request and would
   split anything placed inside that first-60-byte window.)

With both patches, every API call reaches the backend and features work end-to-end.

## Logging

The launch sets `PYTHONUNBUFFERED=1` so all `print`s and werkzeug request logs flush
immediately to the session's `output.log` (without it Python buffers stdout when it isn't a
TTY, so the app looked silent). It also tees the server output to a dedicated
`chainforge.log` in the same OOD session directory as `output.log`. ChainForge's only
`print`-hijack is for users' Python-eval nodes (it captures *their* stdout for the UI) — it
does not touch the Vulcan provider's load/per-request logs, which flow through normally.
Grep `[Vulcan provider]` for provider activity.

## Configuration, persistence & the Vulcan inference API

ChainForge keeps flows, settings, and **custom provider scripts** under `~/.local/share/chainforge/`
(platformdirs default — in the user's `$HOME`), so work survives across sessions. The OOD session
directory (`~/ondemand/.../output`) holds only logs.

### The "Vulcan" provider — wiring in the inference API

`script.sh.erb` seeds a custom provider script into
`~/.local/share/chainforge/provider_scripts/vulcan_provider.py` that ChainForge auto-loads on
startup. It:

- calls `…/serving/api/v1/chat/completions` on each query (OpenAI-compatible);
- authenticates to the **Tyk gateway** with `Authorization: Bearer <token>`. By default all
  users share **one site key** at `/opt/ood/vulcan_tyk.key` (root-owned); `submit.yml.erb`
  injects it into every job as `CF_VULCAN_API_KEY` (rendered on the web node, so it reaches the
  compute node). A per-user `~/.env_tyk` overrides it — the path to per-user keys later. The
  secret is **not** baked into the app source;
- registers a single **"🌋 Vulcan"** provider whose model list is the always-on chat models
  (`gpt-oss-120b`, `gpt-oss-20b`, `command-r-7b` — truly always-on, `gemma-4-26b-a4b`,
  `qwen35-122b`). Add Vulcan, then pick the model in the node's Settings (ChainForge's add-menu
  `>` flyout is a built-in-provider-only feature, so this is the normal custom-provider shape);
- exposes `temperature` / `max_tokens` settings and passes chat history for Chat Turn nodes;
- returns **friendly errors** for the common gateway failures: missing token → "put your key in
  `~/.env_tyk`"; `401` → token rejected; `503` → model warming up, retry;
- **logs every request and error to stdout** → the OOD session `output.log` / `chainforge.log`
  (grep `[Vulcan <model>]`). Verified end-to-end: `command-r-7b` returns a completion.

The model list is **fixed** (not fetched at launch), so there is **no network call at provider
load time** — important because ChainForge deletes any provider script whose `exec` raises.

The built-in OpenAI/Anthropic/etc. providers remain available for users who supply their own keys
(via the UI, or exported before launch — ChainForge reads `OPENAI_API_KEY` etc. natively).

`script.sh.erb` env overrides (read by the seeded provider):

| Env var | Default | Purpose |
|---|---|---|
| `CF_DATA_HOME` | *(unset → `~/.local/share/chainforge`)* | Relocate the ChainForge workspace (`$XDG_DATA_HOME`) |
| `CF_VULCAN_BASE_URL` | `https://inference.kubeflow.vulcan.alliancecan.ca/serving/api/v1` | Inference API base |
| `CF_VULCAN_API_KEY` | *(shared `/opt/ood/vulcan_tyk.key`; overridden by `~/.env_tyk`)* | Tyk gateway bearer token |

> The app intentionally does **not** source `~/.bashrc`. The Vulcan token is read directly from
> `~/.env_tyk` (or `$CF_VULCAN_API_KEY` if already exported). Other providers' keys come from the
> in-UI settings or env vars present when the job starts. ChainForge also speaks **Ollama**.

### Patterns reused from the other Vulcan apps
- Same shared `templates/job_params` + `form_params_cpu_app` form and `CustomClusterInfo`
  initializers as OpenRefine/Octave/Jupyter; **shared `form.js`** (byte-identical to OpenRefine's).
- `view.html.erb` is the same one-line Connect button OpenRefine/RStudio use.
- OIDC email file (`~/ondemand/oidc_email.txt`) for the "email on start" feature.
- The "Vulcan" custom provider auto-discovers chat models from the inference registry, so no
  manual model list needs maintaining (the `paice_*` initializer/cron pattern is the template if
  you ever want them as a *launch-form* dropdown instead).

## Files

| File | Purpose |
|---|---|
| `manifest.yml` | App metadata. Uses ChainForge's own `icon.png` (from the React build). |
| `form.yml.erb` | Mirrors openrefine: shared `job_params` + `form_params_cpu_app` (CPU-only), min 4 cores / 4 GB, memory forced on. |
| `form.js` | Shared dynamic-form JS — byte-identical to the other Vulcan apps. |
| `submit.yml.erb` | Slurm `native` args → `--partition=gpubase_interac`, no `--gres`, **always `--mem` ≥ 4G**. OIDC email file. |
| `view.html.erb` | One-line Connect button → `/rnode/<host>/<port>/` (matches openrefine/rstudio). |
| `template/before.sh.erb` | Allocate port, set `CC_CLUSTER`, `JOB_DIR`. |
| `template/script.sh.erb` | Purge modules, use **`/usr/bin/python3`** (3.12), on-the-fly venv + `pip install chainforge` from PyPI, **reverse-proxy patches** (relative assets + API-base `/`-rewriter for `/rnode/`), workspace-in-home, **seeds the "Vulcan" custom provider**, `PYTHONUNBUFFERED=1` + tee to `chainforge.log`, launches `chainforge serve` (no `~/.bashrc` sourcing; job ends if the server crashes). |
| `template/after.sh.erb` | Wait for the port to come up. |
