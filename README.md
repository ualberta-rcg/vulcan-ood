<img src="https://www.ualberta.ca/en/toolkit/media-library/homepage-assets/ua_logo_green_rgb.png" alt="University of Alberta Logo" width="50%" />

# Vulcan Open OnDemand Deployment

![Ubuntu Version](https://img.shields.io/badge/Ubuntu-22.04+-green?style=flat-square)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

**Maintained by:** Rahim Khoja ([khoja1@ualberta.ca](mailto:khoja1@ualberta.ca))

---

## Description

This repository contains the complete configuration files, scripts, and application definitions for **Open OnDemand (OOD) deployment on the Vulcan HPC cluster** - a Digital Research Alliance of Canada compute resource operated by the University of Alberta as part of the PAICE (Platform for Advanced Infrastructure and Computing Excellence) initiative.

The goal is to provide a reproducible setup for OOD using Apache, OIDC authentication (Shibboleth/Keycloak/AzureAD/etc), and Let's Encrypt SSL. This repository serves as a template that can be adapted for other HPC clusters.

For detailed information about the repository structure and configuration files, see [REPOSITORY_STRUCTURE.md](./REPOSITORY_STRUCTURE.md).

---

## Documentation

- **[REQUIREMENTS.md](./REQUIREMENTS.md)** - System requirements for OOD Server and Compute Node deployments
- **[CONFIGURATION.md](./CONFIGURATION.md)** - Configuration files and settings
- **[REPOSITORY_STRUCTURE.md](./REPOSITORY_STRUCTURE.md)** - Detailed repository structure

---

## Customization for Other Clusters

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

## References

* [Open OnDemand Documentation](https://osc.github.io/ood-documentation/latest/)
* [Digital Research Alliance of Canada](https://alliancecan.ca/en)
* [Vulcan Cluster Documentation](https://docs.alliancecan.ca/wiki/Vulcan)
* [PAICE Platform](https://www.ualberta.ca/information-services-and-technology/research-computing/paice)

---

## Support

This project is provided as-is, but reasonable questions may be answered based on my coffee intake or mood. ;)

Feel free to open an issue or email **[khoja1@ualberta.ca](mailto:khoja1@ualberta.ca)** or **[kali2@ualberta.ca](mailto:kali2@ualberta.ca)** for U of A related deployments.

---

## License

This project is released under the **MIT License** - one of the most permissive open-source licenses available.

**What this means:**
- ✅ Use it for anything (personal, commercial, whatever)
- ✅ Modify it however you want
- ✅ Distribute it freely
- ✅ Include it in proprietary software

**The only requirement:** Keep the copyright notice somewhere in your project.

**Full license text:** [MIT License](./LICENSE)

---

## About University of Alberta Research Computing

The [Research Computing Group](https://www.ualberta.ca/en/information-services-and-technology/research-computing/index.html) supports high-performance computing, data-intensive research, and advanced infrastructure for researchers at the University of Alberta and across Canada.

We help design and operate compute environments that power innovation — from AI training clusters to national research infrastructure, including the Vulcan cluster as part of the Digital Research Alliance of Canada's PAICE (Platform for Advanced Infrastructure and Computing Excellence) initiative.
