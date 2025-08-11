# Configuration Guide

This document outlines the key configuration files and settings for deploying Open OnDemand (OOD) on the Vulcan HPC cluster.

## Core Configuration Files

### 1. Main Portal Configuration (`/etc/ood/config/ood_portal.yml`)

**Purpose**: Apache virtual host configuration with OIDC authentication

**Key Settings**:
- **Server**: `vulcan.alliancecan.ca`
- **Authentication**: OpenID Connect via Alliance Canada
- **SSL**: Custom certificate paths
- **Session**: 8-hour timeout with optional Redis caching
- **Security**: OIDC email claim integration

**Required Changes for Deployment**:
- Update `servername` to your domain
- Configure OIDC provider metadata URL
- Set OIDC client credentials
- Point SSL certificates to your files

**Note**: OIDC authentication requires SSSD (System Security Services Daemon) to be properly configured on all systems for user authentication and home directory mapping.

### 2. Cluster Configuration (`/etc/ood/config/clusters.d/vulcan.yml`)

**Purpose**: SLURM cluster integration and job submission settings

**Key Settings**:
- **Scheduler**: SLURM with `/usr/bin/` binaries
- **Login Host**: `vulcan.alliancecan.ca`
- **Host Allowlist**: `rack*` and `vulcan*` nodes
- **Environment**: No shell environment copying

**Required Changes for Deployment**:
- **Rename file**: Change `vulcan.yml` to match your cluster name (e.g., `mycluster.yml`)
- Update cluster title and login hostname
- Modify host allowlist patterns for your nodes
- Verify SLURM binary and config paths

### 3. Dashboard Configuration (`/etc/ood/config/ondemand.d/ondemand.yml`)

**Purpose**: Web interface branding, layout, and application management

**Key Settings**:
- **Branding**: University of Alberta green theme with AMII logo
- **Help Menu**: Alliance documentation and support links
- **Pinned Apps**: Shell, job management, development tools
- **Globus Integration**: File transfer endpoints for `/home`, `/project`, `/scratch`

**Required Changes for Deployment**:
- Update branding colors and logos
- Configure help menu links for your institution
- Select appropriate pinned applications
- Set Globus endpoints for your file systems
- **Globus Endpoints**: Use UUIDs, not smart names (e.g., `97bda3da-a723-4dc0-ba7e-728f35183b43`)

### 4. Nginx Stage Configuration (`/etc/ood/config/nginx_stage.yml`)

**Purpose**: Per-User Nginx (PUN) environment variables

**Key Settings**:
- **MOTD**: Message of the Day integration
- **Locale**: English-Canadian (`en-CA`) default
- **Format**: Text-based MOTD display

**Required Changes for Deployment**:
- Set appropriate locale for your region
- Configure MOTD path if different

### 5. Shell Application Security (`/etc/ood/config/apps/shell/env`)

**Purpose**: SSH host access control for shell application

**Key Settings**:
- **Host Allowlist**: Restricted to rack nodes and vulcan login nodes
- **Pattern**: `rack[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]:vulcan1:vulcan2:rack*`

**Required Changes for Deployment**:
- Update host patterns to match your compute node naming
- Ensure SSH key-based authentication is configured

### 6. Localization (`/etc/ood/config/locales/`)

**Purpose**: Multi-language interface support

**Files**:
- `en-CA.yml`: English (Canada) translations
- `fr-CA.yml`: French (Canada) translations

**Required Changes for Deployment**:
- Add your preferred languages
- Customize translations for your institution

## System Integration Files

### 7. Message of the Day (`/etc/motd`)

**Purpose**: Welcome message and support information

**Content**: Vulcan cluster welcome with Alliance Canada support contacts

**Required Changes for Deployment**:
- Update welcome message for your cluster
- Modify support contact information

### 8. XDG Runtime Setup (`/etc/sudoers.d/create-ice-xdg`)

**Purpose**: Allow users to create X11 forwarding directories

**Content**: `ALL ALL=(ALL) NOPASSWD: /usr/local/bin/create-ice.sh`

**Required Changes for Deployment**:
- Ensure `create-ice.sh` script exists on compute nodes
- Verify script creates proper XDG runtime directories

## Automated Configuration

### Auto-Generated Files

The following files are automatically generated and should not be edited manually:

- **`/etc/ood/config/apps/dashboard/initializers/paice_cluster_info.rb`**: SLURM partition information
- **`/etc/ood/config/apps/dashboard/initializers/paice_gpu_info.rb`**: GPU types and counts
- **`/etc/ood/config/apps/dashboard/initializers/paice_app_versions.rb`**: Available software versions

### Generation Scripts

Located in `/opt/ood/cron/`:
- `gen_cluster_rb.sh`: Updates cluster information from SLURM
- `gen_gpu_rb.sh`: Discovers GPU configuration
- `gen_app_rb.sh`: Queries environment modules for versions

**Important**: Run these cron scripts **before** starting OOD to populate the initial configuration files. The auto-generated files contain essential cluster information that OOD needs to function properly.

## Configuration Updates

When making configuration changes, use these commands to apply updates:

```bash
# Update OOD portal configuration
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# Clean up user PUN directories (run on all OOD nodes)
sudo /opt/ood/nginx_stage/sbin/nginx_stage nginx_clean --force
```

**Note**: The `nginx_clean` command removes all user PUN directories and should be run on all OOD nodes when making configuration changes.

**Cron Setup**:
- **Copy or symlink** scripts to `/etc/cron.weekly/` or `/etc/cron.d/`
- **Run as root** since scripts need access to SLURM commands and system paths
- **Recommended frequency**: Weekly (cluster configuration changes infrequently)

**Example cron entries** (add to `/etc/cron.d/ood-config`):
```bash
# Update cluster partition information weekly
0 2 * * 0 root /opt/ood/cron/gen_cluster_rb.sh

# Update GPU configuration weekly  
0 3 * * 0 root /opt/ood/cron/gen_gpu_rb.sh

# Update application versions weekly
0 4 * * 0 root /opt/ood/cron/gen_app_rb.sh
```

## Deployment Requirements

### Initial Setup
- **Run cron scripts first** to populate auto-generated files before starting OOD
- **Rename cluster configuration file** to match your cluster (e.g., `mycluster.yml`)
- **Update all hostnames and domains** throughout configuration files
- **Configure OIDC identity provider** with proper client credentials and metadata URLs
- **Generate SSL certificates** valid for your domain
- **Set SLURM paths and host patterns** for your cluster
- **Customize branding and help menu** for your institution
- **Configure file system paths** and Globus endpoint UUIDs (not smart names)

### Additional Configuration Options
Other configuration options are available for Redis session caching, custom applications, monitoring, and backup systems. Refer to the Open OnDemand documentation for advanced configuration options.

## Security Considerations

- **SSL Certificates**: Must be valid for your domain
- **OIDC Secrets**: Store securely, not in plain text
- **Host Allowlists**: Restrict access to authorized nodes only
- **File Permissions**: Private keys should be 600, configs 644
- **Network Access**: Limit to required ports (80, 443, SSH)

