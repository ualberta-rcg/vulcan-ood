# Installation Guide

This document provides step-by-step instructions for installing Open OnDemand (OOD) on Ubuntu 24.04 for the Vulcan HPC cluster.

## Prerequisites

### System Requirements
- **Ubuntu 24.04** (tested and verified)
- **Root/sudo access** on all nodes
- **Network connectivity** between OOD server, compute nodes, storage systems, and slurm network
- **DNS resolution** configured for your OOD domain
- **CVMFS** for application distribution
- **Firewall rules** allowing HTTP/HTTPS (ports 80/443)

### Base System Setup
The following components must be installed and configured **before** OOD installation:

#### SLURM Infrastructure
- **SLURM job scheduler** installed and running
- **SLURM tools** (`squeue`, `sinfo`, `scontrol`) available on OOD server
- **SLURM configuration** (`/etc/slurm/slurm.conf`) accessible
- **MUNGE authentication** service running
- **SLURM controller/database** (slurmctld, slurmdbd) accessible

#### File System Access
- **Home directories** mounted and accessible on all nodes
- **Scratch storage** mounted and accessible on all nodes  
- **Project storage** mounted and accessible on all nodes
- **Shared file systems** accessible from OOD server and compute nodes

#### Authentication & Services
- **SSSD (System Security Services Daemon)** installed and configured
- **OIDC identity provider** configured and accessible
- **User authentication** working against your identity provider
- **Home directory mapping** functional



## OOD Installation

### 1. Install Open OnDemand

```bash
# Install required packages for repository access
sudo apt install apt-transport-https ca-certificates

# Download and install OOD repository package
wget -O /tmp/ondemand-release-web_4.0.0-noble_all.deb https://apt.osc.edu/ondemand/4.0/ondemand-release-web_4.0.0-noble_all.deb
sudo apt install /tmp/ondemand-release-web_4.0.0-noble_all.deb

# Update package list
sudo apt update

# Install OOD, Apache, and OIDC module with required dependencies
sudo apt install ondemand apache2 libapache2-mod-auth-openidc python3-requests python3-requests-oauthlib

# Enable the OIDC module
sudo a2enmod auth_openidc

# Restart Apache to load the module
sudo systemctl restart apache2
```


## Repository Deployment

### 1. Clone the Repository

```bash
# Clone the Vulcan OOD configuration repository
git clone https://github.com/your-org/vulcan-ood.git
cd vulcan-ood
```

### 2. Set Executable Permissions Before Copying

**Important**: Set executable permissions on all shell scripts before copying to avoid chmodding the root filesystem:

```bash
# Make all .sh files executable recursively
find . -name "*.sh" -type f -exec chmod +x {} \;

# Make all .sh.erb files executable recursively  
find . -name "*.sh.erb" -type f -exec chmod +x {} \;

# Verify permissions were set correctly
find . -name "*.sh" -o -name "*.sh.erb" | xargs ls -la

# Note: Other .erb files (form.yml.erb, submit.yml.erb, etc.) are templates and don't need executable permissions
```

### 3. Deploy Configuration Files

```bash
# Copy system configuration files
sudo cp -r etc/* /etc/

# Copy web applications
sudo cp -r var/www/ood/* /var/www/ood/

# Copy OOD scripts and cron jobs
sudo cp -r opt/ood/* /opt/ood/

# Copy user utilities
sudo cp -r usr/local/bin/* /usr/local/bin/


```

### 2. Deploy Cron Scripts

```bash
# Copy cron scripts to system cron directory
sudo cp opt/ood/cron/* /etc/cron.d/

# Set proper permissions
sudo chmod 644 /etc/cron.d/*
sudo chown root:root /etc/cron.d/*
```

### 3. Deploy Ansible Playbooks

Deploy the Ansible playbooks for compute node automation:

```bash
# Create Ansible directory structure
sudo mkdir -p /etc/ansible/playbooks

# Copy Ansible playbooks
sudo cp etc/ansible/playbooks/* /etc/ansible/playbooks/

# Set proper permissions
sudo chmod 644 /etc/ansible/playbooks/*.yaml*
sudo chown root:root /etc/ansible/playbooks/*
```

**Note**: These playbooks are designed to run on compute nodes to prepare them for remote desktop applications. They should be executed after the base system is configured and before users start accessing desktop applications.



## Initial Configuration

### 1. Run Cron Scripts First

**Important**: Run these scripts **before** starting OOD to populate essential configuration files:

```bash
# Generate initial cluster information
sudo /opt/ood/cron/gen_cluster_rb.sh
sudo /opt/ood/cron/gen_gpu_rb.sh
sudo /opt/ood/cron/gen_app_rb.sh
```

### 2. Update Configuration Files

Edit the following files to match your cluster. **See `CONFIGURATION.md` for detailed examples and comments**:

- **`/etc/ood/config/clusters.d/vulcan.yml`** - Rename to match your cluster
  - Contains SLURM integration settings and host allowlist patterns
- **`/etc/ood/config/ood_portal.yml`** - Update domain and OIDC settings
  - Contains Apache virtual host configuration with OIDC authentication
- **`/etc/ood/config/ondemand.d/ondemand.yml`** - Customize branding and help menu
  - Contains web interface branding, layout, and application management
- **`/etc/ood/config/apps/shell/env`** - Update host allowlist patterns
  - Contains SSH host access control for shell application
- **`/etc/ood/config/nginx_stage.yml`** - Per-User Nginx environment variables
- **`/etc/ood/config/locales/`** - Multi-language interface support

### 3. Customize Dashboard Views

**Important**: Customize dashboard appearance for your institution:

```bash
# Edit footer template for institutional branding
sudo nano /etc/ood/config/apps/dashboard/views/layouts/_footer.html.erb

# Edit navigation logo template
sudo nano /etc/ood/config/apps/dashboard/views/layouts/nav/_logo.html.erb
```

**Customization Options**:
- **Footer**: Update support contact information and institutional branding
- **Logo**: Replace with your institution's logo and branding
- **See `CONFIGURATION.md`** for detailed customization examples

### 4. Generate SSL Certificates

```bash
# Create SSL directory
sudo mkdir -p /etc/ssl/ood

# Generate or copy your SSL certificates
sudo cp your-certificate.pem /etc/ssl/ood/fullchain.pem
sudo cp your-private-key.pem /etc/ssl/ood/privkey.pem

# Set proper permissions
sudo chmod 600 /etc/ssl/ood/privkey.pem
sudo chmod 644 /etc/ssl/ood/fullchain.pem
```

## Compute Node Setup

### 1. Install Required Packages

On each compute node:

```bash
# Install VirtualGL (if GPUs present)
sudo apt install virtualgl
```

### 2. Deploy XDG Runtime Script

```bash
# Copy the create-ice script
sudo cp /path/to/repo/usr/local/bin/create-ice.sh /usr/local/bin/
# Note: Permissions are already set from the repository

# Deploy sudoers configuration
sudo cp /path/to/repo/etc/sudoers.d/create-ice-xdg /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/create-ice-xdg
```

### 3. Run Ansible Playbooks

Execute the Ansible playbooks to configure desktop environments and applications:

```bash
# Install desktop environments and VirtualGL
ansible-playbook /etc/ansible/playbooks/40-install-desktop-env.yaml

# Install Google Chrome
ansible-playbook /etc/ansible/playbooks/41-install-chrome.yaml
```

**Note**: These playbooks install multiple desktop environments (GNOME, XFCE, MATE, LXQt), configure VirtualGL for GPU acceleration, and install Chrome for web applications. Run them after the base system is configured.

### 4. Verify File System Access

Ensure each compute node has access to:
- **Home directories** (mounted)
- **Scratch storage** (mounted)
- **Project storage** (mounted)
- **CVMFS** (accessible)

## Start and Test

### 1. Start Apache Service

```bash
# Start and enable Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Note: OOD runs as part of Apache, not as a separate systemd service
```

### 2. Apply Configuration Updates

```bash
# Update OOD portal configuration
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# Clean up user PUN directories (run on all OOD nodes)
sudo /opt/ood/nginx_stage/sbin/nginx_stage nginx_clean --force
```

### 3. Apply Common Fixes

```bash
# Fix XTERM color issue that causes programs like 'top' to fail in shell sessions
sudo sed -i 's/xterm-16color/xterm-256color/g' /var/www/ood/apps/sys/shell/app.js

# Fix remote desktop compression to prevent Zlib errors (minimum value 1 instead of 0)
sudo sed -i '/:compression/ s/min: 0/min: 1/; /:compression/ s/0 (low) to 9/1 (low) to 9/' /var/www/ood/apps/sys/dashboard/app/views/batch_connect/sessions/connections/_novnc.html.erb
```

### 4. Verify Installation

```bash
# Check Apache status
sudo systemctl status apache2

# Verify OIDC module is loaded
apache2ctl -M | grep openidc

# Test web access
curl -k https://your-ood-domain
```

## Post-Installation

### 1. Configure Cron Jobs

The cron scripts should now be running weekly to keep configuration updated:

```bash
# Verify cron jobs are active
sudo crontab -l

# Check cron job logs
sudo tail -f /var/log/cron
```

### 2. Test Applications

- Access the OOD dashboard
- Test shell application
- Launch a simple interactive application
- Verify SLURM job submission

### 3. Verify Dashboard Customization

- Check that custom logo appears in navigation
- Verify footer displays correct institutional branding
- Test that dashboard reflects your customizations

### 4. Monitor Logs

```bash
# OOD logs
sudo tail -f /var/log/ondemand/*

# Apache logs
sudo tail -f /var/log/apache2/ood-*.log

# SLURM logs
sudo tail -f /var/log/slurm/*
```

## OOD Restart Process

When making configuration changes, use this sequence to restart OOD:

```bash
# Clean up user PUN directories (run on all OOD nodes)
sudo /opt/ood/nginx_stage/sbin/nginx_stage nginx_clean --force

# Update OOD portal configuration
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# Restart Apache (OOD runs as part of Apache)
sudo systemctl restart apache2
```

**Note**: OOD does not run as a separate systemd service. It runs as part of Apache, so restarting Apache restarts OOD.

## Troubleshooting

### Common Issues

1. **OIDC Authentication Fails**
   - Verify SSSD configuration
   - Check OIDC provider connectivity
   - Verify SSL certificates
   - Ensure OIDC module is loaded: `apache2ctl -M | grep openidc`

2. **SLURM Integration Issues**
   - Check SLURM commands availability
   - Verify MUNGE authentication
   - Check host allowlist patterns

3. **File System Access Problems**
   - Verify mount points
   - Check CVMFS accessibility
   - Verify user permissions

### Useful Commands

```bash
# Check OOD configuration
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# Restart OOD (Apache restart required)
sudo systemctl restart apache2

# Check SLURM connectivity
sinfo -N -l

# Verify SSSD status
sudo systemctl status sssd
```

## Next Steps

After successful installation:

1. **Customize branding** and help menu for your institution
2. **Configure additional applications** as needed
3. **Set up monitoring** and logging
4. **Configure backup** and recovery procedures
5. **Document** your specific configuration

Refer to `CONFIGURATION.md` for detailed configuration options with examples and comments, and `REQUIREMENTS.md` for system requirements.
