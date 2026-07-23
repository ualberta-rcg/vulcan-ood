# Vulcan OOD app formula

Every interactive app under `var/www/ood/apps/sys/<app>/` follows one of two
templates. Keep new apps consistent with these.

## Shared building blocks (don't duplicate — include them)

`var/www/ood/apps/templates/`:
- `job_params` — common form field **definitions** (num_cores, bc_num_hours,
  bc_email_on_started, bc_vnc_resolution, memtask, gpu_checkbox/type/count,
  add_env, advanced_options)
- `form_params` — field **order** for GPU-capable apps
- `form_params_cpu` — field order for CPU-only apps (no GPU fields)
- `form_params_env` — field order for apps that also expose extra-env setup

An app's `form.yml.erb` pulls these in:
```erb
<% IO.foreach(template_root+"job_params") do |line| %><%= line %><% end %>
...
<% IO.foreach(template_root+"form_params") do |line| %><%= line %><% end %>
```

`gpu_data` in every GPU app's `form.yml.erb` must have all 5 keys:
```ruby
gpu_data = {
  "gpu_types" => CustomGPUInfo.gpu_types,
  "gpu_name_mappings" => CustomGPUInfo.gpu_name_mappings.transform_keys(&:to_s),
  "gpu_max_counts" => CustomGPUInfo.gpu_max_counts.transform_keys(&:to_s),
  "gpu_sharing_available" => (CustomGPUInfo.gpu_sharing_available rescue false),
  "slices_per_gpu" => (CustomGPUInfo.slices_per_gpu rescue nil)
}
```
The shared `form.js` (identical across all GPU apps) renders fractional sizes
from this (softmig: full / ½ / ¼ GPU).

## submit.yml.erb — canonical native args

```erb
<%-
  emailaddr = File.read(File.expand_path('~/ondemand/oidc_email.txt')).strip rescue ''
-%>
batch_connect:
  template: "basic"        # or "vnc" for desktop apps (+ websockify_cmd, vnc_args)
script:
  cluster: "<%= cluster %>"
  <% if defined?(bc_email_on_started) && bc_email_on_started == "1" && emailaddr != "" %>
  email: <%= emailaddr.inspect %>
  <% end %>
  native:
    - "-N"
    - "1"
    - "-n"
    - "<%= num_cores %>"
    - "--time=<%= bc_num_hours %>:00:00"
    <%- if defined?(gpu_checkbox) && gpu_checkbox == "1" && gpu_type != "none" -%>
    - "--gres=gpu:<%= gpu_type %>:<%= gpu_count %>"
    <%- end -%>
    <%- if defined?(memtask_checkbox) && memtask_checkbox == "1" && memtask.present? && memtask != "0" -%>
    - "--mem=<%= memtask %>G"
    <%- end -%>
    - "--partition=gpubase_interac"
    - "--qos=interac"
```

Rules:
- **Always** `--partition=gpubase_interac` + `--qos=interac` (interactive QOS so
  sessions don't queue behind batch jobs).
- GPU apps include the `--gres` block; CPU-only apps omit it.
- Email is read from `~/ondemand/oidc_email.txt` (written by the PUN OIDC hook).

## Two app shapes

| Shape | Apps | template | form include | gres |
|---|---|---|---|---|
| **VNC desktop** | afni, blender, desktop_expert, igv, matlab, octave, paraview, qgis, vmd | `vnc` + `template/desktops/` + `before.sh.erb` | `form_params` (or `_env`) | yes |
| **Basic web** | jupyter, rstudio, vs_code, tensorboard, chainforge, voyant, openrefine | `basic` + `view.html.erb` | `form_params`/`_cpu` | GPU apps yes, CPU apps no |
| **Batch** | alphafold | `basic`, no view | `form_params` | yes |

## CPU-only apps (no GPU)

chainforge_app, voyant_app, openrefine_app, tensorboard_app — use `form_params_cpu`
(or a custom form) and have **no** `--gres` block in submit.

## Line endings

All text files are LF (enforced via `.gitattributes`). Don't commit CRLF.
