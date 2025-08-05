<img src="https://www.ualberta.ca/en/toolkit/media-library/homepage-assets/ua_logo_green_rgb.png" alt="University of Alberta Logo" width="50%" />

# Vulcan Open OnDemand Deployment

[![CI/CD](https://github.com/ualberta-rcg/vulcan-ood/actions/workflows/deploy-ood.yml/badge.svg)](https://github.com/ualberta-rcg/vulcan-ood/actions/workflows/deploy-ood.yml)
![Ubuntu Version](https://img.shields.io/badge/Ubuntu-22.04+-green?style=flat-square)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

**Maintained by:** Rahim Khoja ([khoja1@ualberta.ca](mailto:khoja1@ualberta.ca))

---

## 🧰 Description

This repository contains the complete configuration files, scripts, and application definitions for **Open OnDemand (OOD) deployment on the Vulcan HPC cluster** at the University of Alberta.

The goal is to provide a reproducible setup for OOD using Apache, OIDC authentication (Shibboleth/Keycloak/AzureAD/etc), and Let's Encrypt SSL. This repository serves as a template that can be adapted for other HPC clusters.

*Note: Deployment instructions will be provided via a shell script in the future.*

---

## 📂 Repository Structure

This repository mirrors the filesystem structure of a deployed OOD installation. Here's what each directory contains:

### `/etc/ood/config/` - Core Configuration
- **`ood_portal.yml`** - Main OOD portal configuration (532 lines)
  - Apache virtual host settings
  - SSL configuration
  - Authentication settings
  - Logging configuration
  - Maintenance mode settings

- **`clusters.d/vulcan.yml`** - Vulcan cluster definition
  - SLURM job scheduler configuration
  - Login node settings
  - Host allowlist for job submission

- **`apps/dashboard/`** - Dashboard customizations
  - **`initializers/`** - Ruby modules for cluster info
    - `paice_cluster_info.rb` - Vulcan-specific cluster metadata
    - `paice_gpu_info.rb` - GPU information (auto-generated)
    - `paice_app_versions.rb` - Application version tracking

### `/var/www/ood/apps/sys/` - System Applications
Pre-configured interactive applications for Vulcan:

- **`jupyter_app/`** - JupyterLab server
- **`rstudio_server_app/`** - RStudio Server
- **`matlab_app/`** - MATLAB
- **`paraview_app/`** - ParaView visualization
- **`vmd_app/`** - VMD molecular visualization
- **`blender_app/`** - Blender 3D
- **`qgis_app/`** - QGIS geospatial
- **`octave_app/** - GNU Octave
- **`afni_app/`** - AFNI neuroimaging
- **`vs_code_html_app/`** - VS Code Server
- **`desktop_expert/`** - Remote desktop
- **`myjobs/`** - Job management interface

Each app contains:
- `manifest.yml` - App metadata and description
- `form.yml.erb` - User interface form
- `submit.yml.erb` - Job submission configuration
- `view.html.erb` - App launch interface

### `/usr/local/bin/` - Utility Scripts
- **`create-ice.sh`** - XDG runtime directory setup for compute nodes
  - Creates `/tmp/.ICE-unix` directory
  - Sets up XDG runtime symlinks for user sessions

### `/opt/ood/scripts/` - OOD Integration Scripts
- **`ood_pun_oidc_email.sh`** - OIDC email claim handler
  - Saves user's OIDC email to `~/ondemand/oidc_email.txt`
  - Called by Apache during user authentication

### `/opt/ood/cron/` - Automated Configuration Generators
- **`gen_gpu_rb.sh`** - Auto-generates GPU information from SLURM
  - Queries `scontrol show node` for GPU types and counts
  - Updates `paice_gpu_info.rb` with current cluster GPU configuration
- **`gen_cluster_rb.sh`** - Generates cluster partition information
- **`gen_app_rb.sh`** - Updates application version information

### `/etc/sudoers.d/` - Privilege Configuration
- **`create-ice-xdg`** - Sudoers entry for XDG runtime setup
  - Allows all users to run `create-ice.sh` without password
  - Required for interactive applications on compute nodes

### `/kube/` - Kubernetes Resources
- **`redis.yaml`** - Redis deployment for OOD session management
  - StatefulSet with persistent storage
  - MetalLB load balancer configuration
  - Password-protected Redis instance
  - NFS-based storage class

---

## 🔧 Configuration Details

### Cluster Configuration (`vulcan.yml`)
```yaml
v2:
  metadata:
    title: "Vulcan"
  login:
    host: "vulcan.alliancecan.ca"
  job:
    adapter: "slurm"
    bin: "/usr/bin/"
    conf: "/etc/slurm/slurm.conf"
  submit:
    host_allowlist:
      - "rack*"
      - "vulcan*"
```

### GPU Information (Auto-generated)
The `gen_gpu_rb.sh` script automatically discovers and configures:
- Available GPU types (e.g., A100, V100, RTX4090)
- Maximum GPU counts per type
- GPU name mappings for display

### Application Configuration
Each interactive app includes:
- Resource request forms (CPU, memory, GPU)
- SLURM partition selection
- Application-specific environment setup
- Session timeout and cleanup

---

## 🚨 Known Issues

### Package Installation
The current `apt-get` commands in deployment guides may not be correct for all Ubuntu versions. The Open OnDemand repository structure and package names may vary between Ubuntu releases.

**Recommendation:** Test package installation on your target Ubuntu version before deployment.

---

## 🛠️ Customization for Other Clusters

To adapt this configuration for your own cluster:

1. **Update cluster configuration:**
   - Modify `etc/ood/config/clusters.d/vulcan.yml`
   - Change hostnames, scheduler settings, and partition names

2. **Customize applications:**
   - Edit app manifests in `var/www/ood/apps/sys/`
   - Update resource limits and partition names
   - Modify application descriptions and branding

3. **Update cluster information:**
   - Modify `etc/ood/config/apps/dashboard/initializers/paice_cluster_info.rb`
   - Update partition names, CPU/memory limits
   - Run `gen_gpu_rb.sh` to auto-generate GPU information

4. **Configure authentication:**
   - Update OIDC settings in `ood_portal.yml`
   - Configure your identity provider (Shibboleth, Keycloak, etc.)

5. **Update branding:**
   - Replace University of Alberta logos and references
   - Update application descriptions and help text

---

## 🤝 Support

Open an issue or email **[khoja1@ualberta.ca](mailto:khoja1@ualberta.ca)** for support, or just catch me at 2am on Slack.

---

## 📜 License

MIT License — [see LICENSE](./LICENSE)

---

## 🧠 About University of Alberta Research Computing

The [Research Computing Group](https://www.ualberta.ca/information-services-and-technology/research-computing/) supports high-performance computing, data-intensive research, and advanced infrastructure for researchers at the University of Alberta and across Canada.

---

## 📚 References

* [Open OnDemand Documentation](https://osc.github.io/ood-documentation/latest/)
* [mod_auth_openidc GitHub](https://github.com/zmartzone/mod_auth_openidc)
* [Certbot Guide](https://certbot.eff.org/instructions?ws=apache&os=ubuntufocal)
* [OIDC Protocol Explainer](https://openid.net/connect/)
