<img src="https://www.ualberta.ca/en/toolkit/media-library/homepage-assets/ua_logo_green_rgb.png" alt="University of Alberta Logo" width="50%" />

# Vulcan Open OnDemand Deployment

![Ubuntu Version](https://img.shields.io/badge/Ubuntu-22.04+-green?style=flat-square)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

**Maintained by:** Rahim Khoja ([khoja1@ualberta.ca](mailto:khoja1@ualberta.ca))

---

## 🧰 Description

This repository contains the complete configuration files, scripts, and application definitions for **Open OnDemand (OOD) deployment on the Vulcan HPC cluster** - a Digital Research Alliance of Canada compute resource operated by the University of Alberta as part of the PAICE (Platform for Advanced Infrastructure and Computing Excellence) initiative.

The goal is to provide a reproducible setup for OOD using Apache, OIDC authentication (Shibboleth/Keycloak/AzureAD/etc), and Let's Encrypt SSL. This repository serves as a template that can be adapted for other HPC clusters.

*Note: Deployment instructions will be provided via a shell script in the future.*

For detailed information about the repository structure and configuration files, see [REPOSITORY_STRUCTURE.md](./REPOSITORY_STRUCTURE.md).

---

## ✅ Prerequisites & Requirements

Before deploying Open OnDemand, ensure you have the following in place:

### **System Requirements**
- **Ubuntu 24.04** (or compatible version)
- **Root/sudo access** on the OOD host
- **Public DNS domain** (e.g., `ood.yourcluster.edu`)
- **SSL certificates** for your domain (Let's Encrypt recommended)

### **Network & Infrastructure**
- **Static IP address** for the OOD host
- **DNS resolution** configured for your OOD domain
- **Network connectivity** to compute nodes and login nodes
- **Firewall rules** allowing HTTP/HTTPS traffic (ports 80/443)

### **Authentication & Identity**
- **OIDC Identity Provider** (Shibboleth, Keycloak, AzureAD, etc.)
- **OIDC Client Registration** with your identity provider:
  - Client ID (e.g., `ood.yourcluster.edu`)
  - Client Secret
  - Redirect URIs configured
  - Required scopes: `openid profile email`
- **SSSD (System Security Services Daemon)** installed and configured
  - User authentication against your identity provider
  - Home directory mapping

### **Cluster Integration**
- **SLURM job scheduler** installed and configured
  - SLURM commands available on OOD host (`squeue`, `sinfo`, `scontrol`, etc.)
  - SLURM configuration file (`/etc/slurm/slurm.conf`)
  - **MUNGE** authentication service (required for SLURM)
- **User home directories** mounted or accessible on OOD host
- **Compute node access** from OOD host (SSH key-based authentication)

### **Session Management (Optional)**
- **Kubernetes cluster** (for Redis deployment)
- **MetalLB** load balancer configured
- **NFS storage class** for Redis persistence
- **Redis deployment** for shared session management

### **Open OnDemand Repository**
- **Open OnDemand APT repository** added to your system
- **Apache2** with required modules (`auth_openidc`, `ssl`, `proxy`, `proxy_http`, `rewrite`, `headers`)

### **File System Requirements**
- **/etc/ood/** - Configuration directory
- **/var/www/ood/** - Web application files
- **/opt/ood/** - Scripts and utilities
- **/usr/local/bin/** - Utility scripts
- **/etc/sudoers.d/** - Privilege configuration

### **User Environment**
- **XDG runtime directories** setup on compute nodes
- **User session management** configured
- **Environment modules** (if used by your cluster)

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


## 📚 References

* [Open OnDemand Documentation](https://osc.github.io/ood-documentation/latest/)
* [Digital Research Alliance of Canada](https://alliancecan.ca/en)
* [Vulcan Cluster Documentation](https://docs.alliancecan.ca/wiki/Vulcan)
* [PAICE Platform](https://www.ualberta.ca/information-services-and-technology/research-computing/paice)
* [mod_auth_openidc GitHub](https://github.com/zmartzone/mod_auth_openidc)
* [Certbot Guide](https://certbot.eff.org/instructions?ws=apache&os=ubuntufocal)
* [OIDC Protocol Explainer](https://openid.net/connect/)


## 🤝 Support

Many Bothans died to bring us this information. This project is provided as-is, but reasonable questions may be answered based on my coffee intake or mood. ;)

Feel free to open an issue or email **[khoja1@ualberta.ca](mailto:khoja1@ualberta.ca)** or **[kali2@ualberta.ca](mailto:kali2@ualberta.ca)** for U of A related deployments.

## 📜 License

This project is released under the **MIT License** - one of the most permissive open-source licenses available.

**What this means:**
- ✅ Use it for anything (personal, commercial, whatever)
- ✅ Modify it however you want
- ✅ Distribute it freely
- ✅ Include it in proprietary software

**The only requirement:** Keep the copyright notice somewhere in your project.

That's it! No other strings attached. The MIT License is trusted by major projects worldwide and removes virtually all legal barriers to using this code.

**Full license text:** [MIT License](./LICENSE)

## 🧠 About University of Alberta Research Computing

The [Research Computing Group](https://www.ualberta.ca/en/information-services-and-technology/research-computing/index.html) supports high-performance computing, data-intensive research, and advanced infrastructure for researchers at the University of Alberta and across Canada.

We help design and operate compute environments that power innovation — from AI training clusters to national research infrastructure, including the Vulcan cluster as part of the Digital Research Alliance of Canada's PAICE (Platform for Advanced Infrastructure and Computing Excellence) initiative.
