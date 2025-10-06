# OpenRefine App for Open On Demand

This directory contains the OpenRefine application configuration for Open On Demand, allowing users to run OpenRefine instances on the Vulcan HPC cluster.

## Overview

OpenRefine is a powerful tool for working with messy data: cleaning it; transforming it from one format into another; extending it with web services; and linking it to databases. This Open On Demand app provides a web-based interface to launch OpenRefine instances on compute nodes.

## How It Works

### Automatic Installation Process
1. **Job Submission**: User submits a job through the Open On Demand web interface
2. **Resource Allocation**: SLURM allocates compute resources and assigns a unique port
3. **Automatic Download**: The app downloads OpenRefine 3.9.5 from GitHub releases
4. **Installation**: Extracts and sets up OpenRefine in a job-specific directory
5. **Server Launch**: Starts OpenRefine server with proper configuration
6. **Web Access**: Provides a connection button to access the OpenRefine interface

### Key Features
- **Zero Manual Setup**: OpenRefine is automatically downloaded and installed
- **Dynamic Port Allocation**: Each instance gets a unique port automatically
- **Resource Management**: Users can specify CPU cores and memory requirements
- **Data Persistence**: Projects are saved in job-specific directories
- **Secure Access**: Each instance runs in an isolated environment

## Prerequisites

- **Java Runtime**: Java 17 module is automatically loaded
- **Network Access**: Compute nodes need internet access to download OpenRefine
- **Download Tools**: Either `wget` or `curl` must be available

## Usage

1. **Access the App**: Navigate to the OpenRefine app in the Open On Demand dashboard
2. **Configure Resources**: Set your desired CPU cores (minimum 2) and memory (minimum 4GB)
3. **Submit Job**: Click "Launch" to start your OpenRefine instance
4. **Wait for Startup**: The app will automatically download, install, and start OpenRefine
5. **Connect**: Click "Connect to OpenRefine" to access your instance

## Technical Implementation

### File Structure
- `manifest.yml`: App metadata and description
- `form.yml.erb`: Job submission form with resource selection
- `submit.yml.erb`: SLURM job configuration
- `view.html.erb`: Simple connection interface
- `template/before.sh.erb`: Downloads and installs OpenRefine
- `template/script.sh.erb`: Launches OpenRefine server
- `template/after.sh.erb`: Verifies server is running

### Installation Process (`before.sh.erb`)
1. Allocates a unique port using `find_port`
2. Downloads OpenRefine 3.9.5 tarball from GitHub
3. Extracts to `${PWD}/openrefine-install/openrefine-3.9.5/`
4. Makes the `refine` executable and sets permissions
5. Exports `OPENREFINE_EXECUTABLE` path for the script

### Server Launch (`script.sh.erb`)
1. Loads Java 17 module
2. Uses the downloaded OpenRefine executable
3. Starts OpenRefine with proper command-line options:
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
- **Default Java Memory**: 4GB maximum, 1GB initial
- **Partition**: `gpubase_interac` (interactive jobs)

### Data Storage
- **Working Directory**: `${PWD}/openrefine-data`
- **Installation Directory**: `${PWD}/openrefine-install`
- **Log File**: `${PWD}/openrefine.log`

### OpenRefine Settings
- **Mode**: Headless (no GUI)
- **Interface**: Binds to all interfaces (0.0.0.0)
- **Authentication**: None required (single-user per instance)

## Troubleshooting

### Common Issues

1. **Download Failures**:
   - Check compute node internet connectivity
   - Verify `wget` or `curl` is available
   - Ensure sufficient disk space

2. **Port Allocation Failures**:
   - Usually indicates system resource constraints
   - Try reducing requested resources

3. **Java Errors**:
   - Java 17 module should load automatically
   - Check job logs for module loading issues

4. **Connection Issues**:
   - Verify the server started successfully
   - Check that the port is accessible
   - Review OpenRefine log files

### Log Files
- **OpenRefine Logs**: `${PWD}/openrefine.log`
- **Job Output**: Available in Open On Demand interface
- **System Logs**: Check SLURM and system logs

## Version Information

- **OpenRefine Version**: 3.9.5 (automatically downloaded)
- **Java Version**: 17.0.6 (automatically loaded)
- **Installation**: Fully automatic, no manual setup required
