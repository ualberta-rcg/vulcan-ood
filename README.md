# Open OnDemand (OOD) Deployment on Ubuntu

This repository contains scripts, configs, and instructions to deploy [Open OnDemand](https://openondemand.org/) on Ubuntu using Apache, OIDC authentication, and SSL with Let's Encrypt.

---

## ✅ Requirements

* Ubuntu 20.04 or later
* Root access
* Public DNS domain (e.g. `ood.yourdomain.ca`)
* OIDC provider (e.g. Keycloak, Google, AzureAD, Shibboleth)

---

## 📦 Install Required Packages

```bash
sudo apt update && sudo apt install -y \
  apache2 \
  libapache2-mod-auth-openidc \
  curl \
  gnupg \
  nginx \
  unzip
```

Add the OOD APT repository:

```bash
curl -fsSL https://yum.osc.edu/ondemand/RPM-GPG-KEY-ondemand | \
  gpg --dearmor | sudo tee /usr/share/keyrings/ondemand.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/ondemand.gpg] \
  https://yum.osc.edu/ondemand/3.0/web/ubuntu jammy main" | \
  sudo tee /etc/apt/sources.list.d/ondemand.list

sudo apt update
sudo apt install -y ondemand
```

---

## 🔐 Configure OIDC

Enable required modules and config:

```bash
sudo a2enmod auth_openidc ssl proxy proxy_http rewrite headers
sudo a2enconf ood-portal
sudo systemctl restart apache2
```

---

## 🔄 Regenerate Portal Config

After changing `/etc/ood/config/ood_portal.yml`, apply changes:

```bash
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f
sudo systemctl restart apache2
```

---

## 🔧 NGINX Session Cleanup

If user sessions are broken or misbehaving:

```bash
sudo /opt/ood/nginx_stage/sbin/nginx_stage --clean
```

Or for a specific user:

```bash
sudo /opt/ood/nginx_stage/sbin/nginx_stage --user <username> --clean
```

---

## 📂 App Paths

* System apps: `/var/www/ood/apps/sys/`
* User dev apps: `~/ondemand/dev/`
* Config: `/etc/ood/config/`

---

## 🧪 Test & Debug

* Access: `https://ood.yourdomain.ca/`
* Logs: `/var/log/apache2/error.log`, `/var/log/ondemand-nginx/`
* Restart all:

```bash
sudo systemctl restart apache2
sudo /opt/ood/nginx_stage/sbin/nginx_stage --clean
```

---

## 📚 References

* [Open OnDemand Documentation](https://osc.github.io/ood-documentation/latest/)
* [mod\_auth\_openidc GitHub](https://github.com/zmartzone/mod_auth_openidc)
* [Certbot Guide](https://certbot.eff.org/)
