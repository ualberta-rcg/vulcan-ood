# Repository Structure

This repository mirrors the filesystem structure of a deployed OOD installation. Here's what each directory contains:

## `/etc/ood/config/` - Core Configuration

### **`ood_portal.yml`** - Main OOD portal configuration (532 lines)
- Apache virtual host settings
- SSL configuration
- Authentication settings
- Logging configuration
- Maintenance mode settings

### **`clusters.d/vulcan.yml`** - Vulcan cluster definition
- SLURM job scheduler configuration
- Login node settings
- Host allowlist for job submission

### **`apps/dashboard/`** - Dashboard customizations
- **`initializers/`** - Ruby modules for cluster info
  - `paice_cluster_info.rb` - Vulcan-specific cluster metadata
  - `paice_gpu_info.rb` - GPU information (auto-generated)
  - `paice_app_versions.rb` - Application version tracking

## `/var/www/ood/apps/sys/` - System Applications

Pre-configured interactive applications for Vulcan (Digital Research Alliance of Canada):

### **Mathematics** (2 apps)
- **`jupyter_app/`** - JupyterLab server
- **`rstudio_server_app/`** - RStudio Server

### **Visualization** (5 apps)
- **`paraview_app/`** - ParaView visualization
- **`vmd_app/`** - VMD molecular visualization
- **`blender_app/`** - Blender 3D
- **`qgis_app/`** - QGIS geospatial
- **`afni_app/`** - AFNI neuroimaging

### **Development** (3 apps)
- **`vs_code_html_app/`** - VS Code Server
- **`matlab_app/`** - MATLAB
- **`octave_app/** - GNU Octave

### **Desktop** (1 app)
- **`desktop_expert/`** - Remote desktop

### **System** (1 app)
- **`myjobs/`** - Job management interface

Each app contains:
- `manifest.yml` - App metadata and description
- `form.yml.erb` - User interface form
- `submit.yml.erb` - Job submission configuration
- `view.html.erb` - App launch interface

## `/usr/local/bin/` - Utility Scripts

### **`create-ice.sh`** - XDG runtime directory setup for compute nodes
- Creates `/tmp/.ICE-unix` directory
- Sets up XDG runtime symlinks for user sessions

## `/opt/ood/scripts/` - OOD Integration Scripts

### **`ood_pun_oidc_email.sh`** - OIDC email claim handler
- Saves user's OIDC email to `~/ondemand/oidc_email.txt`
- Called by Apache during user authentication

## `/opt/ood/cron/` - Automated Configuration Generators

### **`gen_gpu_rb.sh`** - Auto-generates GPU information from SLURM
- Queries `scontrol show node` for GPU types and counts
- Updates `paice_gpu_info.rb` with current cluster GPU configuration

### **`gen_cluster_rb.sh`** - Generates cluster partition information
### **`gen_app_rb.sh`** - Updates application version information

## `/etc/sudoers.d/` - Privilege Configuration

### **`create-ice-xdg`** - Sudoers entry for XDG runtime setup
- Allows all users to run `create-ice.sh` without password
- Required for interactive applications on compute nodes

## `/kube/` - Kubernetes Resources

### **`redis.yaml`** - Redis deployment for OOD session management
- StatefulSet with persistent storage
- MetalLB load balancer configuration
- Password-protected Redis instance
- NFS-based storage class

## Configuration Details

### Cluster Configuration (`vulcan.yml`)
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

### GPU Information (Auto-generated)
The `gen_gpu_rb.sh` script automatically discovers and configures:
- Available GPU types (e.g., A100, V100, RTX4090)
- Maximum GPU counts per type
- GPU name mappings for display

### Application Configuration
Each interactive app includes:
- Resource request forms (CPU, memory, GPU)
- SLURM partition selection
- Application-specific environment setup
- Session timeout and cleanup 