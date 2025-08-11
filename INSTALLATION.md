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
# Add OOD repository
curl -s https://osc.github.io/ondemand/repo/ondemand.repo | sudo tee /etc/apt/sources.list.d/ondemand.repo

# Update package list
sudo apt update

# Install OOD
sudo apt install ondemand
```

### 2. Install Apache OIDC Module

```bash
# Install Apache OIDC module for authentication
sudo apt install libapache2-mod-auth-openidc

# Enable required Apache modules
sudo a2enmod ssl
sudo a2enmod auth_openidc
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod headers
sudo a2enmod rewrite
```


## Repository Deployment

### 1. Clone the Repository

```bash
# Clone the Vulcan OOD configuration repository
git clone https://github.com/your-org/vulcan-ood.git
cd vulcan-ood
```

### 2. Deploy Configuration Files

```bash
# Copy system configuration files
sudo cp -r etc/* /etc/

# Copy web applications
sudo cp -r var/www/ood/* /var/www/ood/

# Copy OOD scripts and cron jobs
sudo cp -r opt/ood/* /opt/ood/

# Copy user utilities
sudo cp -r usr/local/bin/* /usr/local/bin/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/ood
sudo chmod 755 /usr/local/bin/create-ice.sh
```

### 3. Deploy Cron Scripts

```bash
# Copy cron scripts to system cron directory
sudo cp opt/ood/cron/* /etc/cron.d/

# Set proper permissions
sudo chmod 644 /etc/cron.d/*
sudo chown root:root /etc/cron.d/*
```

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

Edit the following files to match your cluster:

- **`/etc/ood/config/clusters.d/vulcan.yml`** - Rename to match your cluster
- **`/etc/ood/config/ood_portal.yml`** - Update domain and OIDC settings
- **`/etc/ood/config/ondemand.d/ondemand.yml`** - Customize branding and help menu
- **`/etc/ood/config/apps/shell/env`** - Update host allowlist patterns

### 3. Generate SSL Certificates

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
sudo chmod 755 /usr/local/bin/create-ice.sh

# Deploy sudoers configuration
sudo cp /path/to/repo/etc/sudoers.d/create-ice-xdg /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/create-ice-xdg
```

### 3. Verify File System Access

Ensure each compute node has access to:
- **Home directories** (mounted)
- **Scratch storage** (mounted)
- **Project storage** (mounted)
- **CVMFS** (accessible)

## Start and Test

### 1. Start OOD Services

```bash
# Start Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Start OOD services
sudo systemctl start ondemand
sudo systemctl enable ondemand
```

### 2. Apply Configuration Updates

```bash
# Update OOD portal configuration
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# Clean up user PUN directories (run on all OOD nodes)
sudo /opt/ood/nginx_stage/sbin/nginx_stage nginx_clean --force
```

### 3. Verify Installation

```bash
# Check OOD status
sudo systemctl status ondemand

# Check Apache status
sudo systemctl status apache2

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

### 3. Monitor Logs

```bash
# OOD logs
sudo tail -f /var/log/ondemand/*

# Apache logs
sudo tail -f /var/log/apache2/ood-*.log

# SLURM logs
sudo tail -f /var/log/slurm/*
```

## Troubleshooting

### Common Issues

1. **OIDC Authentication Fails**
   - Verify SSSD configuration
   - Check OIDC provider connectivity
   - Verify SSL certificates

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

# Restart OOD services
sudo systemctl restart ondemand

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

Refer to `CONFIGURATION.md` for detailed configuration options and `REQUIREMENTS.md` for system requirements.
