# Configuration Guide

This document explains all the configuration files and settings needed to deploy Open OnDemand (OOD) for your HPC cluster. Each section details the current Vulcan configuration and what you need to change for your environment.

## 🔧 Core Configuration Files

### **Main Portal Configuration** (`/etc/ood/config/ood_portal.yml`)

This is the primary configuration file for the OOD portal. Here's the current Vulcan configuration with explanations:

```yaml
---
# Server Configuration
servername: vulcan.alliancecan.ca                    # CHANGE: Your OOD domain
node_uri: "/node"                                    # OOD node URI (usually keep default)
rnode_uri: "/rnode"                                  # OOD reverse node URI (usually keep default)

# Logging
errorlog: 'ood-error.log'                            # Error log filename
accesslog: 'ood-access.log'                          # Access log filename

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
oidc_state_max_number_of_cookies: "10 true"

# OIDC Advanced Settings
oidc_settings:
  OIDCPassIDTokenAs: "serialized"
  OIDCPassRefreshToken: "On"
  OIDCPassClaimsAs: "environment"
  OIDCStripCookies: "mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1"
  OIDCResponseType: "code"
  OIDCXForwardedHeaders: "X-Forwarded-Proto"

# SSL Configuration
ssl:
  - 'SSLCertificateFile "/etc/ssl/ood/fullchain.pem"'    # CHANGE: Your SSL certificate path
  - 'SSLCertificateKeyFile "/etc/ssl/ood/privkey.pem"'   # CHANGE: Your SSL private key path

# Debugging
custom_vhost_directives:
  - 'LogLevel auth_openidc:debug'
```

**Required Changes:**
1. **Domain**: Change `servername` to your OOD domain
2. **OIDC Provider**: Update metadata URL and client credentials
3. **SSL Certificates**: Point to your SSL certificate files
4. **Logout URL**: Configure your identity provider logout URL

### **Nginx Stage Configuration** (`/etc/ood/config/nginx_stage.yml`)

```yaml
pun_custom_env:
  MOTD_PATH: "/etc/motd"                             # Message of the Day file
  MOTD_FORMAT: "txt"                                 # MOTD format (txt/html)
  OOD_LOCALE: "en-CA"                                # CHANGE: Your locale (en-US, fr-CA, etc.)
```

**Required Changes:**
1. **Locale**: Set to your preferred locale
2. **MOTD**: Ensure `/etc/motd` exists or change path

### **Cluster Configuration** (`/etc/ood/config/clusters.d/vulcan.yml`)

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
1. **Cluster Name**: Update title and hostname
2. **Login Node**: Set your login node hostname
3. **Job Scheduler**: Verify SLURM paths or change to your scheduler
4. **Host Allowlist**: Update compute node naming patterns

### **Dashboard Configuration** (`/etc/ood/config/ondemand.d/ondemand.yml`)

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
  # ... more help menu items

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

# Globus Integration (Optional)
globus_endpoints:                                    # CHANGE: Your Globus endpoints
  - path: "/home"
    endpoint: "97bda3da-a723-4dc0-ba7e-728f35183b43"
    endpoint_path: "/home"
  - path: "/project"
    endpoint: "97bda3da-a723-4dc0-ba7e-728f35183b43"
    endpoint_path: "/project"
  - path: "/scratch"
    endpoint: "97bda3da-a723-4dc0-ba7e-728f35183b43"
    endpoint_path: "/scratch"
```

**Required Changes:**
1. **Branding**: Update title, logos, colors, and CSS
2. **Help Menu**: Configure your documentation and support links
3. **Pinned Apps**: Choose which apps to pin to dashboard
4. **Globus**: Configure your Globus endpoints (optional)

## 🔐 Authentication & Security

### **OIDC Identity Provider Setup**

You need to register your OOD instance with your identity provider:

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

### **SSL Certificate Requirements**

**Certificate Files:**
- **Certificate**: `/etc/ssl/ood/fullchain.pem`
- **Private Key**: `/etc/ssl/ood/privkey.pem`

**Certificate Requirements:**
- Valid for your OOD domain
- Issued by a trusted Certificate Authority
- Include full certificate chain
- Proper file permissions (600 for private key)

**Let's Encrypt Setup:**
```bash
# Install Certbot
sudo apt install certbot python3-certbot-apache

# Obtain certificate
sudo certbot --apache -d your-ood-domain.com

# Copy certificates to OOD location
sudo cp /etc/letsencrypt/live/your-ood-domain.com/fullchain.pem /etc/ssl/ood/
sudo cp /etc/letsencrypt/live/your-ood-domain.com/privkey.pem /etc/ssl/ood/
sudo chmod 600 /etc/ssl/ood/privkey.pem
```

### **Message of the Day** (`/etc/motd`)

```bash
###############################################################################

             _                                  Welcome to Vulcan
            | |
__   ___   _| | ___ __ _ _ __      Support:         support@tech.alliancecan.ca
\ \ / / | | | |/ __/ _` | '_ \     Documentation:           docs.alliancecan.ca
 \ V /| |_| | | (_| (_| | | | |    Portal: https://portal.vulcan.alliancecan.ca
  \_/  \__,_|_|\___\__,_|_| |_|    OOD:           https://vulcan.alliancecan.ca
                                   Helpy:     https://chat.cluster.paice-ua.com

###############################################################################
```

**Required Changes:**
1. **Cluster Name**: Update welcome message
2. **Support Info**: Update contact information
3. **Portal URLs**: Update your portal and documentation links

## 🌐 Internationalization

### **Locale Configuration**

**Available Locales:**
- `en-CA.yml` - English (Canada)
- `fr-CA.yml` - French (Canada)

## 🐳 Kubernetes Configuration (Optional)

### **Redis Session Management** (`/kube/redis.yaml`)

**Required Changes:**
1. **Namespace**: Update if needed
2. **IP Address**: Change MetalLB IP to available address
3. **Network Interface**: Update to your network interface
4. **Storage Class**: Ensure NFS storage class exists
5. **Password**: Change Redis password

**Deployment:**
```bash
# Apply Redis configuration
kubectl apply -f kube/redis.yaml

# Verify deployment
kubectl get pods -n redis-system
kubectl get svc -n redis-system
```

## 🔄 Automated Configuration

### **GPU Information Generator** (`/opt/ood/cron/gen_gpu_rb.sh`)

**Purpose:**
- Auto-discovers GPU types and counts from SLURM
- Updates `/etc/ood/config/apps/dashboard/initializers/paice_gpu_info.rb`
- Runs via cron job

**Configuration:**
- No changes needed if using SLURM
- Updates automatically when GPU configuration changes

### **Cluster Information Generator** (`/opt/ood/cron/gen_cluster_rb.sh`)

**Purpose:**
- Extracts SLURM partition information
- Updates `/etc/ood/config/apps/dashboard/initializers/paice_cluster_info.rb`
- Auto-discovers CPU and memory limits

**Configuration:**
- No changes needed if using SLURM
- Updates automatically when cluster configuration changes

### **Application Version Generator** (`/opt/ood/cron/gen_app_rb.sh`)

**Purpose:**
- Queries environment modules for software versions
- Updates `/etc/ood/config/apps/dashboard/initializers/paice_app_versions.rb`
- Supports multiple applications

**Supported Applications:**
- RStudio Server
- VS Code Server
- ParaView
- QGIS
- Blender
- Octave
- MuJoCo
- AFNI
- MATLAB
- VMD
