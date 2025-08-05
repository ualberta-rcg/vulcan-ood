<img src="https://www.ualberta.ca/en/toolkit/media-library/homepage-assets/ua_logo_green_rgb.png" alt="University of Alberta Logo" width="50%" />

# Vulcan Open OnDemand Deployment

[![CI/CD](https://github.com/ualberta-rcg/vulcan-ood/actions/workflows/deploy-ood.yml/badge.svg)](https://github.com/ualberta-rcg/vulcan-ood/actions/workflows/deploy-ood.yml)
![Ubuntu Version](https://img.shields.io/badge/Ubuntu-22.04+-green?style=flat-square)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

**Maintained by:** Rahim Khoja ([khoja1@ualberta.ca](mailto:khoja1@ualberta.ca))

---

## 🧰 Description

This repository contains scripts, config files, and instructions to **deploy Open OnDemand (OOD) on Ubuntu** for the Vulcan HPC cluster at the University of Alberta.

The goal is to provide an automated, reproducible setup for OOD using Apache, OIDC authentication (Shibboleth/Keycloak/AzureAD/etc), and Let’s Encrypt SSL.

*No Docker image (yet)—eventually will have an installer script!*

---

## ✅ Requirements

* Ubuntu 20.04 or 22.04 (recommended)
* Root/sudo access
* Public DNS domain (e.g. `vulcan-ood.ualberta.ca`)
* OIDC provider (e.g. Shibboleth, Keycloak, Google, AzureAD)

---

## 📦 Installation Steps

### 1. **Install Required Packages**

```bash
sudo apt update && sudo apt install -y \
  apache2 \
  libapache2-mod-auth-openidc \
  curl \
  gnupg \
  nginx \
  unzip
```

### 2. **Add Open OnDemand APT Repository**

```bash
curl -fsSL https://yum.osc.edu/ondemand/RPM-GPG-KEY-ondemand | \
  gpg --dearmor | sudo tee /usr/share/keyrings/ondemand.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/ondemand.gpg] \
  https://yum.osc.edu/ondemand/3.0/web/ubuntu jammy main" | \
  sudo tee /etc/apt/sources.list.d/ondemand.list

sudo apt update
sudo apt install -y ondemand
```

### 3. **Configure OIDC + SSL**

Enable required Apache modules and config:

```bash
sudo a2enmod auth_openidc ssl proxy proxy_http rewrite headers
sudo a2enconf ood-portal
sudo systemctl restart apache2
```

Obtain SSL certs using Let’s Encrypt (Certbot):

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d vulcan-ood.ualberta.ca
```

### 4. **Regenerate Portal Config After Changes**

Whenever you change `/etc/ood/config/ood_portal.yml`:

```bash
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f
sudo systemctl reload apache2
```

---

## 🖥️ App & Config Paths

* **System apps:** `/var/www/ood/apps/sys/`
* **User dev apps:** `~/ondemand/dev/`
* **Config:** `/etc/ood/config/`

---

## 🧪 Test & Debug

* Access your portal: `https://vulcan-ood.ualberta.ca/`
* Apache logs: `/var/log/apache2/error.log`
* OOD logs: `/var/log/ondemand-nginx/`
* Restart everything:

  ```bash
  sudo systemctl restart apache2
  sudo /opt/ood/nginx_stage/sbin/nginx_stage --clean
  ```

---

## 🛠️ GitHub Actions - CI/CD Pipeline

This repo includes a (future) GitHub Actions workflow for linting, validating configs, and (eventually) triggering install scripts remotely.

* Manual: Run workflow via Actions tab
* Automatic: On push to `main`/`latest`

---

## 📂 Vulcan OOD Configuration

Vulcan-specific overlays, templates, and customizations are in the `overlays/` directory.

---

**PUT STUFF HERE**
*(e.g. custom overlays, site branding, helpful scripts, OIDC sample configs, user guide PDFs, etc)*

---

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
* [mod\_auth\_openidc GitHub](https://github.com/zmartzone/mod_auth_openidc)
* [Certbot Guide](https://certbot.eff.org/instructions?ws=apache&os=ubuntufocal)
* [OIDC Protocol Explainer](https://openid.net/connect/)
