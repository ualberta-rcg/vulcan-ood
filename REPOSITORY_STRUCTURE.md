# Repository Structure

This repository contains the complete Open OnDemand (OOD) deployment configuration for the Vulcan HPC cluster. The structure mirrors the filesystem layout of a deployed OOD installation, organized by infrastructure components and deployment targets.

## 🏗️ Infrastructure Components

### **OOD Portal Server** (`/etc/ood/`, `/var/www/ood/`, `/opt/ood/`)

#### **Core Configuration** (`/etc/ood/config/`)
- **`ood_portal.yml`** - Main OOD portal configuration
  - Apache virtual host settings and SSL configuration
  - OIDC authentication settings (Shibboleth/Keycloak integration)
  - Session management and logging configuration
  - Maintenance mode and security settings

- **`nginx_stage.yml`** - Nginx stage configuration
  - Custom environment variables for PUN (Per-User Nginx)
  - MOTD (Message of the Day) integration
  - Locale settings (en-CA, fr-CA)

- **`clusters.d/vulcan.yml`** - Vulcan cluster definition
  - SLURM job scheduler configuration
  - Login node settings and host allowlist
  - Job submission and resource management

- **`apps/dashboard/`** - Dashboard customizations
  - **`initializers/`** - Ruby modules for dynamic cluster info
    - `paice_cluster_info.rb` - Auto-generated cluster metadata
    - `paice_gpu_info.rb` - Auto-generated GPU information
    - `paice_app_versions.rb` - Auto-generated application versions

- **`apps/shell/env`** - Shell application environment
  - SSH host allowlist for compute node access
  - Security and access control settings

- **`locales/`** - Internationalization
  - `en-CA.yml` - English (Canada) translations
  - `fr-CA.yml` - French (Canada) translations

#### **Web Applications** (`/var/www/ood/apps/sys/`)
Pre-configured interactive applications organized by category:

##### **Mathematics** (2 apps)
- **`jupyter_app/`** - JupyterLab server for interactive computing
- **`rstudio_server_app/`** - RStudio Server for R development

##### **Visualization** (5 apps)
- **`paraview_app/`** - Scientific visualization and data analysis
- **`vmd_app/`** - Molecular visualization and analysis
- **`blender_app/`** - 3D modeling, animation, and rendering
- **`qgis_app/`** - Geographic information system (GIS)
- **`afni_app/`** - fMRI data visualization and analysis

##### **Development** (3 apps)
- **`vs_code_html_app/`** - VS Code Server for web-based development
- **`matlab_app/`** - MATLAB numerical computing environment
- **`octave_app/`** - GNU Octave open-source numerical computing

##### **Desktop** (1 app)
- **`desktop_expert/`** - Remote desktop environment

##### **System** (1 app)
- **`myjobs/`** - Job management and monitoring interface

Each application contains:
- `manifest.yml` - Application metadata and description
- `form.yml.erb` - User interface form configuration
- `submit.yml.erb` - Job submission and SLURM integration
- `view.html.erb` - Application launch interface
- `template/` - Application-specific templates and scripts

#### **Public Assets** (`/var/www/ood/public/`)
- **`ualberta/`** - University of Alberta branding
  - `logo.png` - U of A logo
  - `branding.css` - Custom styling
  - `favicon.ico` - Site favicon
- **`amii/`** - AMII branding
  - `amii-logo.png` - AMII logo
- **`drac/`** - Digital Research Alliance of Canada branding
  - `drac_banner.png` - DRAC banner

#### **Utility Scripts** (`/usr/local/bin/`)
- **`create-ice.sh`** - XDG runtime directory setup for compute nodes
  - Creates `/tmp/.ICE-unix` directory for X11 forwarding
  - Sets up XDG runtime symlinks for user sessions
  - Required for interactive applications on compute nodes

#### **OOD Integration Scripts** (`/opt/ood/scripts/`)
- **`ood_pun_oidc_email.sh`** - OIDC email claim handler
  - Saves user's OIDC email to `~/ondemand/oidc_email.txt`
  - Called by Apache during user authentication
  - Enables email-based notifications and user management

#### **Automated Configuration Generators** (`/opt/ood/cron/`)
- **`gen_gpu_rb.sh`** - Auto-generates GPU information from SLURM
  - Queries `scontrol show node` for GPU types and counts
  - Updates `paice_gpu_info.rb` with current cluster GPU configuration
  - Supports dynamic GPU discovery (A100, V100, RTX4090, etc.)

- **`gen_cluster_rb.sh`** - Generates cluster partition information
  - Extracts SLURM partition names and resource limits
  - Updates `paice_cluster_info.rb` with current cluster configuration
  - Auto-discovers CPU and memory limits per node

- **`gen_app_rb.sh`** - Updates application version information
  - Queries environment modules for available software versions
  - Updates `paice_app_versions.rb` with current application versions
  - Supports: RStudio, VS Code, ParaView, QGIS, Blender, Octave, MuJoCo, AFNI, etc.

#### **Privilege Configuration** (`/etc/sudoers.d/`)
- **`create-ice-xdg`** - Sudoers entry for XDG runtime setup
  - Allows all users to run `create-ice.sh` without password
  - Required for interactive applications on compute nodes
  - Security configuration for user session management

#### **System Messages** (`/etc/`)
- **`motd`** - Message of the Day
  - Welcome message for Vulcan cluster
  - Support contact information and portal links
  - Integration with OOD dashboard

## 🐳 Kubernetes Infrastructure

### **Session Management** (`/kube/`)
- **`redis.yaml`** - Redis deployment for OOD session management
  - **Namespace**: `redis-system` for isolation
  - **Secret**: Password-protected Redis authentication
  - **StatefulSet**: Persistent storage with NFS backend
  - **MetalLB**: Load balancer configuration for external access
  - **Storage**: NFS-based persistent volume claims
  - **Network**: L2 advertisement for IP allocation

## 🔧 Configuration Details

### **Cluster Configuration** (`vulcan.yml`)
```yaml
v2:
  metadata:
    title: "Vulcan"
  login:
    host: "vulcan.alliancecan.ca"
  job:
    adapter: "slurm"
    bin: "/usr/bin/"
    conf: "/etc/slurm/slurm.conf"
  submit:
    host_allowlist:
      - "rack*"
      - "vulcan*"
```

### **OIDC Authentication** (`ood_portal.yml`)
- **Provider**: Digital Research Alliance of Canada identity provider
- **Client**: `vulcan.alliancecan.ca`
- **Scopes**: `openid profile email`
- **Session**: 8-hour timeout with refresh tokens
- **Integration**: Email claim extraction for user management

### **Auto-Generated Components**
The system includes three automated configuration generators:

1. **GPU Discovery** - Automatically detects available GPU types and counts
2. **Cluster Info** - Extracts SLURM partition and resource information
3. **App Versions** - Queries environment modules for software versions

### **Application Configuration**
Each interactive application includes:
- Resource request forms (CPU, memory, GPU)
- SLURM partition selection
- Application-specific environment setup
- Session timeout and cleanup
- VNC integration for GUI applications

## 🎯 Deployment Targets

### **OOD Portal Server**
- Apache2 with OIDC authentication
- SSL/TLS termination
- Session management and load balancing
- User interface and application routing

### **Compute Nodes**
- SLURM job execution
- XDG runtime directory setup
- Interactive application hosting
- GPU acceleration support

### **Kubernetes Cluster**
- Redis session storage
- MetalLB load balancing
- NFS persistent storage
- Container orchestration

## 🔄 Automation & Maintenance

### **Cron Jobs**
- GPU information updates
- Cluster configuration synchronization
- Application version discovery
- System health monitoring

### **Security**
- OIDC-based authentication
- SSH key-based compute node access
- Sudoers configuration for user sessions
- SSL/TLS encryption

### **Monitoring**
- Apache access and error logs
- SLURM job monitoring
- Redis session tracking
- Application health checks 