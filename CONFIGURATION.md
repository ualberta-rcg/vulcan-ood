# Configuration Guide

This document outlines the key configuration files and settings needed to deploy Open OnDemand (OOD) for your HPC cluster.

## Core Configuration Files

### Main Portal Configuration (`/etc/ood/config/ood_portal.yml`)

```yaml
---
# Server Configuration
servername: vulcan.alliancecan.ca                    # CHANGE: Your OOD domain
node_uri: "/node"                                    # OOD node URI (usually keep default)
rnode_uri: "/rnode"                                  # OOD reverse node URI (usually keep default)

# Authentication Configuration
auth:
  - "AuthType openid-connect"                        # OIDC authentication
  - "Require valid-user"                             # Require valid user

# OIDC Logout
logout_redirect: "https://idp.alliancecan.ca/idp/profile/Logout?return=https://alliancecan.ca"
# CHANGE: Update with your identity provider logout URL

# OIDC Email Integration
pun_pre_hook_root_cmd: "/opt/ood/scripts/ood_pun_oidc_email.sh"
pun_pre_hook_exports: "OIDC_CLAIM_email"

# OIDC Provider Settings
oidc_uri: "/oidc"
oidc_provider_metadata_url: "https://idp.alliancecan.ca/.well-known/openid-configuration"
# CHANGE: Update with your identity provider metadata URL

oidc_client_id: "vulcan.alliancecan.ca"             # CHANGE: Your OOD client ID
oidc_client_secret: "OIDC_SECRET"                   # CHANGE: Your OIDC client secret
oidc_remote_user_claim: "preferred_username"         # User identifier claim
oidc_scope: "openid profile email"                   # Required OIDC scopes
oidc_session_inactivity_timeout: 28800               # 8-hour session timeout
oidc_session_max_duration: 28800                     # 8-hour max session duration

# SSL Configuration
ssl:
  - 'SSLCertificateFile "/etc/ssl/ood/fullchain.pem"'    # CHANGE: Your SSL certificate path
  - 'SSLCertificateKeyFile "/etc/ssl/ood/privkey.pem"'   # CHANGE: Your SSL private key path
```

**Required Changes:**
- **Domain**: Change `servername` to your OOD domain
- **OIDC Provider**: Update metadata URL and client credentials
- **SSL Certificates**: Point to your SSL certificate files
- **Logout URL**: Configure your identity provider logout URL

### Nginx Stage Configuration (`/etc/ood/config/nginx_stage.yml`)

```yaml
pun_custom_env:
  MOTD_PATH: "/etc/motd"                             # Message of the Day file
  MOTD_FORMAT: "txt"                                 # MOTD format (txt/html)
  OOD_LOCALE: "en-CA"                                # CHANGE: Your locale (en-US, fr-CA, etc.)
```

**Required Changes:**
- **Locale**: Set to your preferred locale

### Cluster Configuration (`/etc/ood/config/clusters.d/vulcan.yml`)

```yaml
---
v2:
  metadata:
    title: "Vulcan"                                  # CHANGE: Your cluster name
  login:
    host: "vulcan.alliancecan.ca"                    # CHANGE: Your login node hostname
  job:
    adapter: "slurm"                                 # Job scheduler (slurm, pbs, etc.)
    bin: "/usr/bin/"                                 # SLURM binary path
    conf: "/etc/slurm/slurm.conf"                    # SLURM config file path
    copy_environment: false                           # Don't copy environment
  submit:
    host_allowlist:                                  # CHANGE: Your compute node patterns
      - "rack*"
      - "vulcan*"
```

**Required Changes:**
- **Cluster Name**: Update title and hostname
- **Login Node**: Set your login node hostname
- **Job Scheduler**: Verify SLURM paths or change to your scheduler
- **Host Allowlist**: Update compute node naming patterns

### Dashboard Configuration (`/etc/ood/config/ondemand.d/ondemand.yml`)

```yaml
# Branding
dashboard_title: "Vulcan HPC Cluster"                # CHANGE: Your cluster title
dashboard_header_img_logo: "/public/ualberta/logo.png"  # CHANGE: Your logo path
public_url: "/public/ualberta/"                      # CHANGE: Your public assets path
brand_bg_color: "#007C41"                           # CHANGE: Your brand color
brand_link_active_bg_color: "#005A2C"               # CHANGE: Your active link color

# Logo
dashboard_logo: "/public/amii/amii-logo.png"        # CHANGE: Your logo
dashboard_logo_height: 150

# Styling
custom_css_files:
  - "branding.css"                                   # CHANGE: Your CSS file

# Help Menu
help_menu:
  - group: "Alliance Documentation"                  # CHANGE: Your help menu groups
  - title: "Vulcan HPC Cluster Information"
    icon: "fas://brain"
    url: "https://docs.alliancecan.ca/wiki/Vulcan"  # CHANGE: Your documentation URL

# Pinned Applications
pinned_apps:                                         # CHANGE: Your preferred apps
  - sys/shell
  - sys/myjobs
  - sys/activejobs
  - sys/system-status
  - sys/desktop_expert
  - sys/jupyter_app
  - sys/rstudio_server_app
  - sys/vs_code_html_app

# Dashboard Layout
dashboard_layout:
  rows:
    - columns:
      - width: 8
        widgets:
          - motd
          - pinned_apps
```

**Required Changes:**
- **Branding**: Update title, logos, colors, and CSS
- **Help Menu**: Configure your documentation and support links
- **Pinned Apps**: Choose which apps to pin to dashboard

## SSL Certificate Requirements

**Certificate Files:**
- **Certificate**: `/etc/ssl/ood/fullchain.pem`
- **Private Key**: `/etc/ssl/ood/privkey.pem`

**Certificate Requirements:**
- Valid for your OOD domain
- Issued by a trusted Certificate Authority
- Include full certificate chain
- Proper file permissions (600 for private key)

## OIDC Identity Provider Setup

**Required OIDC Configuration:**
- **Client ID**: Your OOD domain (e.g., `ood.yourcluster.edu`)
- **Client Secret**: Secure secret from your identity provider
- **Redirect URIs**: `https://your-ood-domain/oidc`
- **Scopes**: `openid profile email`
- **Response Type**: `code`

**Supported Identity Providers:**
- **Shibboleth**: Common in academic environments
- **Keycloak**: Open-source identity management
- **Azure AD**: Microsoft cloud identity
- **Google**: Google Workspace integration
- **Okta**: Enterprise identity platform

## Kubernetes Configuration (Optional)

### Redis Session Management (`/kube/redis.yaml`)

**Required Changes:**
- **Namespace**: Update if needed
- **IP Address**: Change MetalLB IP to available address
- **Network Interface**: Update to your network interface
- **Storage Class**: Ensure NFS storage class exists
- **Password**: Change Redis password

## Automated Configuration

### GPU Information Generator (`/opt/ood/cron/gen_gpu_rb.sh`)
- Auto-discovers GPU types and counts from SLURM
- Updates `/etc/ood/config/apps/dashboard/initializers/paice_gpu_info.rb`
- Runs via cron job

### Cluster Information Generator (`/opt/ood/cron/gen_cluster_rb.sh`)
- Extracts SLURM partition information
- Updates `/etc/ood/config/apps/dashboard/initializers/paice_cluster_info.rb`
- Auto-discovers CPU and memory limits

### Application Version Generator (`/opt/ood/cron/gen_app_rb.sh`)
- Queries environment modules for software versions
- Updates `/etc/ood/config/apps/dashboard/initializers/paice_app_versions.rb`
- Supports multiple applications
