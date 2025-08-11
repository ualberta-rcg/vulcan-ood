# Repository Structure

This repository contains the complete Open OnDemand (OOD) deployment configuration for the Vulcan HPC cluster. The structure mirrors the filesystem layout of a deployed OOD installation.

## Repository File Structure

```
vulcan-ood/                                 # Repository root
├── .git/                                  # Git version control
├── LICENSE                                # MIT License
├── README.md                              # Project overview
├── CONFIGURATION.md                       # This configuration guide
├── REQUIREMENTS.md                        # System requirements
├── REPOSITORY_STRUCTURE.md                # Detailed structure documentation
│
├── etc/                                   # System configuration files
│   ├── motd                               # System-wide Message of the Day
│   ├── sudoers.d/
│   │   └── create-ice-xdg                 # XDG runtime setup permissions
│   └── ood/                               # Open OnDemand configuration
│       └── config/
│           ├── ood_portal.yml             # Main OOD portal configuration
│           ├── nginx_stage.yml            # PUN environment variables
│           ├── ood_portal.sha256sum      # Apache config checksum
│           ├── clusters.d/
│           │   └── vulcan.yml            # Vulcan cluster definition
│           ├── ondemand.d/
│           │   └── ondemand.yml          # Dashboard customization
│           ├── locales/                   # Internationalization
│           │   ├── en-CA.yml             # English (Canada) translations
│           │   └── fr-CA.yml             # French (Canada) translations
│           └── apps/                      # Application configurations
│               ├── dashboard/             # Dashboard customizations
│               │   └── initializers/      # Auto-generated Ruby modules
│               │       ├── paice_cluster_info.rb    # SLURM partition info
│               │       ├── paice_gpu_info.rb        # GPU configuration
│               │       └── paice_app_versions.rb    # Software versions
│               └── shell/
│                   └── env                # Shell app security settings
│
├── opt/                                   # Optional software and scripts
│   └── ood/
│       ├── cron/                          # Automated configuration generators
│       │   ├── gen_cluster_rb.sh         # Generate cluster info from SLURM
│       │   ├── gen_gpu_rb.sh             # Discover GPU configuration
│       │   └── gen_app_rb.sh             # Query environment modules
│       └── scripts/                       # OOD integration scripts
│           └── ood_pun_oidc_email.sh     # OIDC email claim handler
│
├── usr/                                   # User utilities
│   └── local/
│       └── bin/
│           └── create-ice.sh             # XDG runtime setup script
│
├── var/                                   # Variable data
│   └── www/                               # Web applications
│       └── ood/
│           ├── apps/                      # Interactive applications
│           │   └── sys/                   # System applications
│           │       ├── jupyter_app/       # JupyterLab server
│           │       ├── rstudio_server_app/ # RStudio Server
│           │       ├── vs_code_html_app/  # VS Code Server
│           │       ├── matlab_app/        # MATLAB environment
│           │       ├── paraview_app/      # Scientific visualization
│           │       ├── blender_app/       # 3D modeling
│           │       ├── qgis_app/          # Geographic information system
│           │       ├── afni_app/          # fMRI data analysis
│           │       ├── vmd_app/           # Molecular visualization
│           │       ├── octave_app/        # GNU Octave
│           │       ├── desktop_expert/    # Remote desktop
│           │       ├── shell/             # Terminal access
│           │       └── myjobs/            # Job management
│           ├── templates/                 # Form parameter templates
│           │   ├── form_params            # Common form parameters
│           │   ├── form_params_cpu        # CPU-focused parameters
│           │   ├── form_params_env        # Environment parameters
│           │   └── job_params             # SLURM job parameters
│           └── public/                    # Static assets
│               ├── ualberta/              # University of Alberta branding
│               │   ├── logo.png           # UofA logo
│               │   ├── branding.css       # Custom styling
│               │   └── favicon.ico        # Site favicon
│               ├── amii/                  # AMII branding
│               │   └── amii-logo.png     # AMII logo
│               └── drac/                  # DRAC branding
│                   └── drac_banner.png    # DRAC banner
│
└── kube/                                  # Kubernetes infrastructure (optional)
    └── redis.yaml                         # Redis deployment for session management
```

## Infrastructure Components

### OOD Portal Server (`/etc/ood/`, `/var/www/ood/`, `/opt/ood/`)

#### Core Configuration (`/etc/ood/config/`)
- **`ood_portal.yml`** - Main OOD portal configuration
  - Apache virtual host settings and SSL configuration
  - OIDC authentication settings
  - Session management and logging configuration

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

- **`ondemand.d/ondemand.yml`** - Dashboard configuration
  - Custom branding and styling (Vulcan HPC Cluster theme)
  - Help menu with external links (Alliance docs, support, tools)
  - Pinned applications configuration (shell, myjobs, desktop, dev tools)
  - Dashboard layout and widgets
  - Globus file transfer endpoints (`/home`, `/project`, `/scratch`)

- **`ondemand.d/motd`** - Message of the Day for dashboard
  - Welcome message for Vulcan platform
  - Support contact information

#### Web Applications (`/var/www/ood/apps/sys/`)
Pre-configured interactive applications:

##### Development & Data Science (3 apps)
- **`jupyter_app/`** - JupyterLab server for interactive computing
- **`rstudio_server_app/`** - RStudio Server for R development
- **`vs_code_html_app/`** - VS Code Server for web-based development

##### Mathematics & Computing (2 apps)
- **`matlab_app/`** - MATLAB numerical computing environment
- **`octave_app/`** - GNU Octave open-source numerical computing

##### Visualization & Graphics (5 apps)
- **`paraview_app/`** - Scientific visualization and data analysis
- **`vmd_app/`** - Molecular visualization and analysis
- **`blender_app/`** - 3D modeling, animation, and rendering
- **`qgis_app/`** - Geographic information system (GIS)
- **`afni_app/`** - fMRI data visualization and analysis

##### Desktop (1 app)
- **`desktop_expert/`** - Remote desktop environment

##### System (1 app)
- **`myjobs/`** - Job management and monitoring interface

Each application contains:
- `manifest.yml` - Application metadata and description
- `form.yml.erb` - User interface form configuration
- `submit.yml.erb` - Job submission and SLURM integration
- `template/` - Application-specific templates and scripts
- `icon.png` - Application icon (most apps)
- `form.js` - Client-side form validation and behavior

Additional files for specific applications:
- `info.html.erb` - Additional information page (MATLAB, VMD)
- `view.html.erb` - Custom application view (Jupyter, RStudio, VS Code)
- `template/after.sh.erb` - Post-launch scripts (Jupyter, RStudio, VS Code)
- `template/assets/` - Application-specific assets (Jupyter: Python/Julia logos)
- `template/desktops/` - Desktop environment scripts (VNC apps)

#### Application Templates (`/var/www/ood/apps/templates/`)
Reusable template components for application forms:
- **`form_params`** - Common form parameters shared across applications
- **`form_params_cpu`** - CPU-focused application form parameters
- **`form_params_env`** - Environment-specific form parameters
- **`job_params`** - SLURM job submission parameter templates

#### Public Assets (`/var/www/ood/public/`)
- **`ualberta/`** - University of Alberta branding
  - `logo.png` - U of A logo
  - `branding.css` - Custom styling
  - `favicon.ico` - Site favicon
- **`amii/`** - AMII branding
  - `amii-logo.png` - AMII logo
- **`drac/`** - Digital Research Alliance of Canada branding
  - `drac_banner.png` - DRAC banner

#### OOD Integration Scripts (`/opt/ood/scripts/`)
- **`ood_pun_oidc_email.sh`** - OIDC email claim handler
  - Saves user's OIDC email to `~/ondemand/oidc_email.txt`
  - Called by Apache during user authentication

#### Automated Configuration Generators (`/opt/ood/cron/`)
- **`gen_gpu_rb.sh`** - Auto-generates GPU information from SLURM
  - Queries `scontrol show node` for GPU types and counts
  - Updates `paice_gpu_info.rb` with current cluster GPU configuration

- **`gen_cluster_rb.sh`** - Generates cluster partition information
  - Extracts SLURM partition names and resource limits
  - Updates `paice_cluster_info.rb` with current cluster configuration

- **`gen_app_rb.sh`** - Updates application version information
  - Queries environment modules for available software versions
  - Updates `paice_app_versions.rb` with current application versions

#### System Messages (`/etc/`)
- **`motd`** - Message of the Day
  - Welcome message for Vulcan cluster
  - Support contact information and portal links

## Compute Node Infrastructure

#### Utility Scripts (`/usr/local/bin/`)
- **`create-ice.sh`** - XDG runtime directory setup for compute nodes
  - Creates `/tmp/.ICE-unix` directory for X11 forwarding
  - Sets up XDG runtime symlinks for user sessions

#### Privilege Configuration (`/etc/sudoers.d/`)
- **`create-ice-xdg`** - Sudoers entry for XDG runtime setup
  - Allows all users to run `create-ice.sh` without password

## Kubernetes Infrastructure (Optional)

### Session Management (`/kube/`)
- **`redis.yaml`** - Redis deployment for OOD session management
  - **Namespace**: `redis-system` for isolation
  - **Secret**: Password-protected Redis authentication
  - **StatefulSet**: Persistent storage with NFS backend
  - **MetalLB**: Load balancer configuration for external access
