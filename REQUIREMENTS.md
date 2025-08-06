# Requirements

This document outlines the essential requirements for deploying Open OnDemand (OOD) on your HPC cluster.

## OOD Server Requirements

### System Requirements
- **Ubuntu 24.04** (tested and built from this version)
- **Root/sudo access** on the OOD host
- **Public DNS domain** (e.g., `ood.yourcluster.edu`)
- **SSL certificates** for your domain
- **CVMFS** for application distribution

### Network Requirements
- **DNS resolution** configured for your OOD domain
- **Network connectivity** to compute nodes and login nodes
- **Firewall rules** allowing HTTP/HTTPS traffic (ports 80/443)
- **Network access** to SLURM cluster

### Authentication Requirements
- **OIDC Identity Provider** (Shibboleth or other OIDC-compliant provider)
- **OIDC Client Registration** with your identity provider:
  - Client ID (e.g., `ood.yourcluster.edu`)
  - Client Secret
  - Redirect URIs: `https://your-ood-domain/oidc`
  - Required scopes: `openid profile email`
- **SSSD (System Security Services Daemon)** installed and running
  - User authentication against your identity provider
  - Home directory mapping

### Cluster Integration
- **SLURM job scheduler** installed and configured
  - SLURM commands available on OOD host (`squeue`, `sinfo`, `scontrol`)
  - SLURM configuration file (`/etc/slurm/slurm.conf`) must be available
  - **MUNGE** authentication service (required for SLURM)
- **User home directories** mounted and accessible on OOD host
- **Compute node access** from OOD host (SSH key-based authentication)

### File System Requirements
- **/etc/ood/** - Configuration directory
- **/var/www/ood/** - Web application files
- **/opt/ood/** - Scripts and utilities
- **/usr/local/bin/** - Utility scripts
- **/etc/sudoers.d/** - Privilege configuration

### Optional Components
- **Redis** for session management (recommended for multiple OOD deployments)

## Compute Node Requirements

### System Requirements
- **Linux distribution** compatible with your cluster
- **SSH access** from OOD server
- **User home directories** accessible
- **CVMFS** for application distribution
- **VirtualGL** installed for GPU applications

### XDG Runtime Setup
- **`/usr/local/bin/create-ice.sh`** script installed
  - Creates `/tmp/.ICE-unix` directory for X11 forwarding
  - Sets up XDG runtime symlinks (`/run/user/$UID` → `/tmp/xdg-runtime-$UID`)
  - Called by OOD applications during job startup
- **Sudoers configuration** (`/etc/sudoers.d/create-ice-xdg`)
  - Allows all users to run `create-ice.sh` without password
  - Required for interactive applications on compute nodes
  - Entry: `ALL ALL=(ALL) NOPASSWD: /usr/local/bin/create-ice.sh`

### Session Management
- **XDG runtime directories** setup for user sessions
- **X11 forwarding** support for graphical applications
- **Environment modules** (if used by your cluster)

### File System
- **/tmp/.ICE-unix** directory for X11 forwarding (created by `create-ice.sh`)
- **User session directories** for interactive applications

### Network
- **SSH connectivity** from OOD server
- **Network access** to shared file systems
- **DNS resolution** for compute node hostnames 
