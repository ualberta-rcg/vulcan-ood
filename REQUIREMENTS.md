# Requirements

This document outlines the essential requirements for deploying Open OnDemand (OOD) on your HPC cluster.

## OOD Server Requirements

### System Requirements
- **Ubuntu 22.04+** or compatible Linux distribution
- **Root/sudo access** on the OOD host
- **Public DNS domain** (e.g., `ood.yourcluster.edu`)
- **SSL certificates** for your domain

### Network Requirements
- **Static IP address** for the OOD host
- **DNS resolution** configured for your OOD domain
- **Network connectivity** to compute nodes and login nodes
- **Firewall rules** allowing HTTP/HTTPS traffic (ports 80/443)

### Authentication Requirements
- **OIDC Identity Provider** (Shibboleth or other OIDC-compliant provider)
- **OIDC Client Registration** with your identity provider:
  - Client ID (e.g., `ood.yourcluster.edu`)
  - Client Secret
  - Redirect URIs: `https://your-ood-domain/oidc`
  - Required scopes: `openid profile email`

### Cluster Integration
- **SLURM job scheduler** installed and configured
  - SLURM commands available on OOD host (`squeue`, `sinfo`, `scontrol`)
  - SLURM configuration file (`/etc/slurm/slurm.conf`)
- **User home directories** mounted or accessible on OOD host
- **Compute node access** from OOD host (SSH key-based authentication)

### File System Requirements
- **/etc/ood/** - Configuration directory
- **/var/www/ood/** - Web application files
- **/opt/ood/** - Scripts and utilities
- **/usr/local/bin/** - Utility scripts
- **/etc/sudoers.d/** - Privilege configuration

### Optional Components
- **Kubernetes cluster** (for Redis session management)
- **CVMFS** for application distribution (recommended)

## Compute Node Requirements

### System Requirements
- **Linux distribution** compatible with your cluster
- **SSH access** from OOD server
- **User home directories** accessible

### Session Management
- **XDG runtime directories** setup for user sessions
- **X11 forwarding** support for graphical applications
- **Environment modules** (if used by your cluster)

### File System
- **/tmp/.ICE-unix** directory for X11 forwarding
- **User session directories** for interactive applications

### Network
- **SSH connectivity** from OOD server
- **Network access** to shared file systems
- **DNS resolution** for compute node hostnames 