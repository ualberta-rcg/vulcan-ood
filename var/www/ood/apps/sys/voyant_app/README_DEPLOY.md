# Voyant Tools — Open OnDemand app — deployment notes

A Batch Connect interactive app for [Voyant Tools](https://voyant-tools.org/), built to match
the conventions of the other Vulcan interactive apps (shared `templates/job_params`,
`CustomClusterInfo` initializers, OIDC email file).

## How it works

- Voyant runs as a **headless embedded-Jetty server** (`VoyantServer.jar`, launched with
  `headless=true`) on a compute node — no GUI controller, no Docker/Apptainer needed.
- Requires **Java 11 specifically** → loads `StdEnv/2023 java/11.0.22`.
- Submits to **`gpubase_interac`** (same partition as the other apps), no `--gres` (Voyant is
  CPU-only). Users choose the runtime via "Number of hours".
- **Reverse proxy:** Voyant supports a **context path**, so `script.sh.erb` launches it with
  `context_path=/node/<host>/<port>/` and OOD's `/node/` proxy serves it. One catch:
  `Voyant.getBaseUrlString(request)` builds **absolute** `//<host>:<port>/...` URLs from the
  request `Host` header — under `/node/` that host:port is the unreachable compute node, which
  breaks every iframe/panel/corpus URL (cross-origin). `script.sh.erb` patches all `*/index.jsp`
  entry points to emit a **path-only** base (`request.getContextPath()+"/"`) so URLs resolve
  against the OOD origin. Idempotent.
- Corpora are stored under `$SCRATCH/voyant/data` so they persist across sessions.

## Getting the VoyantServer distribution (~490 MB)

Voyant is not in CVMFS and not in the Alliance container registry. The VoyantServer ZIP
(latest **2.6.21**) is **~490 MB** — too large to download per user. **Pre-stage it once**:

```bash
# On a node with internet (e.g. login node, or a short job), into shared /project space:
VOYANT_VERSION=2.6.21
curl -L -o VoyantServer.zip \
  https://github.com/voyanttools/VoyantServer/releases/download/${VOYANT_VERSION}/VoyantServer.zip
unzip VoyantServer.zip        # produces a VoyantServer-<ver>/ dir containing VoyantServer.jar + _app/
# Place somewhere shared & persistent, e.g.:
#   /project/<name>/voyant-server/VoyantServer.jar
```

Then point the app at it by setting `VOYANT_HOME` (the directory containing `VoyantServer.jar`)
in the job environment. To do that for all users, add to `submit.yml.erb` under `script:`:

```yaml
    job_environment:
      VOYANT_HOME: "/project/<name>/voyant-server"
```

If `VOYANT_HOME` is **not** set, the job falls back to a per-user download into
`$SCRATCH/voyant` on first launch (cached afterwards) — this needs outbound internet from the
compute node and a ~490 MB one-time download.

## Install

```bash
sudo cp -r ~/voyant_app /var/www/ood/apps/sys/voyant_app
sudo chown -R root:root /var/www/ood/apps/sys/voyant_app
sudo chmod +x /var/www/ood/apps/sys/voyant_app/template/*.erb
```

No restart needed — OOD discovers `sys` apps automatically.

## Memory

`submit.yml.erb` always requests an **8 GB floor** (`--mem=8G`, or the user's choice if raised).
Voyant's JVM heap is **4096 MB** (`VOYANT_MEM`, overridable via the job environment) on top of the
cluster's global `JAVA_TOOL_OPTIONS=-Xmx2g`; 8 GB node RAM is confirmed working (the default ~500 MB
OOMs it). Raise `VOYANT_MEM` for very large corpora and the `--mem` floor to match.

## Known issues / open questions

- **Upload / cross-origin-frame (FIXED):** Voyant's `Voyant.getBaseUrlString(request)` writes
  **absolute** `//<host>:<port>/node/<host>/<port>/` URLs into every page, derived from the
  request `Host`. Under OOD's `/node/` proxy the backend sees `Host=<compute-node>:<port>`, so
  every iframe/panel/corpus URL pointed at the *unreachable compute node* — a different origin
  from the OOD vhost — tripping the same-origin policy and breaking uploads. Jetty sends no
  `X-Frame-Options`/CSP, so framing was never the issue. `script.sh.erb` patches all nine
  `*/index.jsp` entry points to emit a **path-only** base (`request.getContextPath()+"/"`), so
  the browser resolves all URLs against the OOD origin (verified direct-to-backend: `baseUrl`
  becomes `/node/<host>/<port>/`). No global OOD config change needed.
- **`java.net.BindException: Address already in use`** in the log: Voyant opens a second,
  **hardcoded "admin" port (34000)** in addition to the main port. The main port is unique per
  session (via `find_port`), but 34000 is fixed — so two Voyant sessions on the *same* compute
  node would collide there. Usually harmless for a single session (it was seen alongside the OOM
  kill); revisit if you run concurrent instances.
- **"Is there a fancier server version?"** — Yes, two deployment shapes exist:
  - `VoyantServer.jar` (what we use, headless) — the desktop-style launcher, easiest.
  - The main **`voyanttools/Voyant`** repo builds a `.war` deployed in **Tomcat** (this is what
    voyant-tools.org runs). It's the server-grade, multi-user, reverse-proxy-friendly option and
    more likely to handle the upload/proxy cleanly — but it needs a Tomcat install + the war
    (build it or fetch a release). Worth the switch if the iframe/upload issue can't be resolved.

## First-launch check

The first launch (per user, if using the download fallback) takes a few minutes for the ~490 MB
download + Jetty startup. Watch progress in the OOD session's `output.log`. On the connect link,
the Voyant home page should load fully at `/node/<host>/<port>/` with all panels working.

## Files

| File | Purpose |
|---|---|
| `manifest.yml` | App metadata (no `icon` key — OOD auto-uses the bundled `icon.png`). |
| `icon.png` | Voyant's owl logo (from the shipped `resources/images/voyant-logo-90.png`, 90×90 RGBA). |
| `form.yml.erb` | Mirrors the other Vulcan apps: shared `job_params` + `form_params_cpu_app`, shared `form.js`, hidden GPU/min fields, **min 4 cores / 8 GB**. |
| `form.js` | Shared dynamic-form JS — byte-identical to OpenRefine/ChainForge. |
| `submit.yml.erb` | Slurm `native` args → `--partition=gpubase_interac` (no `--gres`), **always `--mem` ≥ 8G**. OIDC email file. |
| `view.html.erb` | One-line Connect button → `/node/<host>/<port>/` (same style as the other apps). |
| `template/before.sh.erb` | Allocate port, set `CC_CLUSTER`, `JOB_DIR`. |
| `template/script.sh.erb` | Load `java/11.0.22`, locate/download VoyantServer, **patch `*/index.jsp` for `/node/` proxy (path-only baseUrl)**, `exec` headless with `context_path` (job ends if the server crashes). |
| `template/after.sh.erb` | Wait for the port to come up. |
