# OpenRefine App for Open On Demand

This directory contains the OpenRefine application configuration for Open On Demand, allowing users to run OpenRefine instances on the Vulcan HPC cluster.

## Overview

OpenRefine is a power tool that allows you to load data, understand it, clean it up, reconcile it, and augment it with data coming from the web. This Open On Demand app provides a web-based interface to launch OpenRefine instances on compute nodes using the cluster’s **CVMFS** software stack.

## How It Works

### Startup Process
1. **Job Submission**: User submits a job through the Open On Demand web interface
2. **Resource Allocation**: SLURM allocates compute resources and assigns a unique port
3. **Module Load**: The app loads `StdEnv/2023` and `openrefine/3.9.3` from CVMFS (no download)
4. **Server Launch**: Starts the OpenRefine server from the module with proper configuration
5. **Web Access**: Provides a connection button to access the OpenRefine interface

### Key Features
- **CVMFS / Module**: Uses cluster module `openrefine/3.9.3` (requires `StdEnv/2023`); no download or local install
- **Dynamic Port Allocation**: Each instance gets a unique port automatically
- **Resource Management**: Users can specify CPU cores and memory requirements
- **Data Persistence**: Projects are saved in job-specific directories
- **Secure Access**: Each instance runs in an isolated environment

## Prerequisites

- **Environment Modules**: `openrefine/3.9.3` and its dependency `StdEnv/2023` must be available (e.g. `module spider openrefine`)
- **CVMFS**: OpenRefine is served from CVMFS; compute nodes must have CVMFS mounted

## Usage

1. **Access the App**: Navigate to the OpenRefine app in the Open On Demand dashboard
2. **Configure Resources**: Set your desired CPU cores (minimum 2) and memory (minimum 4GB)
3. **Submit Job**: Click "Launch" to start your OpenRefine instance
4. **Wait for Startup**: The app will load the OpenRefine module and start the server
5. **Connect**: Click "Connect to OpenRefine" to access your instance

## Technical Implementation

### File Structure
- `manifest.yml`: App metadata and description
- `form.yml.erb`: Job submission form with resource selection
- `submit.yml.erb`: SLURM job configuration
- `view.html.erb`: Simple connection interface
- `template/before.sh.erb`: Sets up port, password, and working directory
- `template/script.sh.erb`: Loads OpenRefine module and launches server
- `template/after.sh.erb`: Verifies server is running

### Setup (`before.sh.erb`)
1. Allocates a unique port using `find_port`
2. Creates OpenRefine working directory `${PWD}/openrefine-data`
3. Sets `OPENREFINE_WORKDIR` and `OPENREFINE_LOG_FILE` for the launch script

### Server Launch (`script.sh.erb`)
1. Loads `StdEnv/2023` and `openrefine/3.9.3` (CVMFS)
2. Resolves `refine` from the module’s PATH
3. Starts OpenRefine with:
   - `-p ${port}`: Port number
   - `-d ${OPENREFINE_WORKDIR}`: Data directory
   - `-x refine.headless=true`: Headless mode
   - `-i 0.0.0.0`: Bind to all interfaces

### Verification (`after.sh.erb`)
1. Waits for the port to become available
2. Verifies OpenRefine server is responding
3. Provides connection information

## Configuration

### Resource Requirements
- **Minimum**: 2 CPU cores, 4GB RAM
- **Partition**: `gpubase_interac` (interactive jobs)

### Data Storage
- **Working Directory**: `${PWD}/openrefine-data`
- **Log File**: `${PWD}/openrefine.log`

### OpenRefine Settings
- **Mode**: Headless (no GUI)
- **Interface**: Binds to all interfaces (0.0.0.0)
- **Authentication**: None required (single-user per instance)

## Troubleshooting

### Common Issues

1. **Module Not Found**:
   - Run `module spider openrefine` on a login node to confirm `openrefine/3.9.3` and `StdEnv/2023` are available
   - Ensure CVMFS is mounted on the compute node (e.g. `/cvmfs/soft.computecanada.ca`)

2. **Port Allocation Failures**:
   - Usually indicates system resource constraints
   - Try reducing requested resources

3. **`refine` Not in PATH**:
   - After loading the module, `refine` should be on PATH; check job logs for module load errors

4. **Connection Issues**:
   - Verify the server started successfully
   - Check that the port is accessible
   - Review OpenRefine log files

### Log Files
- **OpenRefine Logs**: `${PWD}/openrefine.log`
- **Job Output**: Available in Open On Demand interface
- **System Logs**: Check SLURM and system logs

## Version Information

- **OpenRefine Version**: 3.9.3 (from CVMFS module `openrefine/3.9.3`)
- **Module Dependency**: `StdEnv/2023`
- **Installation**: No local install; uses cluster CVMFS/module stack
