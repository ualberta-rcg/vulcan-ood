# Requirements

This document outlines the essential requirements for deploying Open OnDemand (OOD) on your HPC cluster.

## System Requirements

### Operating System
- **Ubuntu 24.04** (tested and built from this version)
- **Root/sudo access** on the OOD host
- **SSH access** for the users

### Network Requirements
- **DNS resolution** configured for your OOD domain
- **Network connectivity** to compute nodes and login nodes
- **Firewall rules** allowing HTTP/HTTPS traffic (ports 80/443)
- **Network access** to SLURM cluster

## Authentication Requirements

### OIDC Identity Provider
- **OIDC-compliant provider** (Shibboleth, Keycloak, Azure AD, etc.)
- **OIDC Client Registration** with your identity provider:
  - Client ID (e.g., `ood.yourcluster.edu`)
  - Client Secret
  - Redirect URIs: `https://your-ood-domain/oidc`
  - Required scopes: `openid profile email`
  - Response Type: `code`

### SSSD Integration
- **SSSD (System Security Services Daemon)** installed and running
- **User authentication** against your identity provider
- **Home directory mapping** for user accounts
- **Group membership** synchronization

## Cluster Integration

### SLURM Requirements
- **SLURM job scheduler** installed and configured
- **SLURM commands** available on OOD host (`squeue`, `sinfo`, `scontrol`)
- **SLURM configuration file** (`/etc/slurm/slurm.conf`) must be accessible
- **MUNGE authentication service** (required for SLURM)

### File System Access
- **User home directories** mounted and accessible on OOD host
- **Shared file systems** accessible from all nodes
- **Compute node access** from OOD host (SSH key-based authentication)

## Node Requirements

### All Systems (OOD Server, Login Nodes, Compute Nodes)
Each system must have:
- **Home directories** (shared across all nodes)
- **SLURM tools** and client commands
- **SLURM controller/database access** (slurmctld, slurmdbd)
- **SSSD** for authentication and user management
- **CVMFS** for application distribution
- **SSH** access configured

### OOD Server Specific
- **Public DNS domain** (e.g., `ood.yourcluster.edu`)
- **SSL certificates** for your domain
- **Apache/Nginx** web server
- **Ruby** runtime environment

### Compute Node Specific
- **VirtualGL** installed for GPU applications
- **XDG runtime setup** script (`/usr/local/bin/create-ice.sh`)
- **Sudoers configuration** for XDG runtime creation

## Optional Components

### Session Management
- **Redis** for session management (recommended for multiple OOD deployments)
- **Kubernetes** for containerized session management

### Additional Features
- **Globus** for file transfer integration
- **Monitoring** and logging systems
- **Backup** and recovery solutions 
