# Open WebUI App for Open On Demand

This directory contains the Open WebUI application configuration for Open On Demand, allowing users to run Open WebUI instances on the Vulcan HPC cluster.

## Overview

Open WebUI is an extensible, feature-rich, and user-friendly self-hosted WebUI designed to operate entirely offline. It supports various LLM runners, including Ollama and OpenAI-compatible APIs. This Open On Demand app provides a web-based interface to launch Open WebUI instances on compute nodes.

## How It Works

### Automatic Installation Process
1. **Job Submission**: User submits a job through the Open On Demand web interface
2. **Resource Allocation**: SLURM allocates compute resources and assigns a unique port
3. **Virtual Environment Setup**: Creates a Python virtual environment in `/tmp/${USER}_webui_env`
4. **Module Loading**: Loads required modules (python/3.12.4, rust/1.91.0, arrow, opencv) before creating venv
5. **Package Installation**: Installs open-webui and dependencies via pip
6. **Server Launch**: Starts Open WebUI server with proper configuration
7. **Web Access**: Provides a connection button to access the Open WebUI interface

### Key Features
- **Zero Manual Setup**: Open WebUI is automatically installed in a virtual environment
- **Dynamic Port Allocation**: Each instance gets a unique port automatically
- **Resource Management**: Users can specify CPU cores and memory requirements
- **Data Persistence**: Chat history and data are saved in job-specific directories
- **Secure Access**: Each instance runs in an isolated environment
- **Authentication Disabled**: Uses OOD's authentication, no separate login required

## Prerequisites

- **Python 3.12.4**: Automatically loaded via module system
- **Rust 1.91.0**: Required for some Python packages, automatically loaded
- **Arrow Module**: Required dependency, automatically loaded
- **OpenCV Module**: Required dependency, automatically loaded
- **Network Access**: Compute nodes need internet access to install packages via pip

## Usage

1. **Access the App**: Navigate to the Open WebUI app in the Open On Demand dashboard
2. **Configure Resources**: Set your desired CPU cores (minimum 4) and memory (minimum 8GB)
3. **Submit Job**: Click "Launch" to start your Open WebUI instance
4. **Wait for Startup**: The app will automatically create venv, install packages, and start Open WebUI
5. **Connect**: Click "Connect to Open WebUI" to access your instance

## Technical Implementation

### File Structure
- `manifest.yml`: App metadata and description
- `form.yml.erb`: Job submission form with resource selection
- `submit.yml.erb`: SLURM job configuration
- `view.html.erb`: Simple connection interface
- `form.js`: Client-side form validation (shared with other apps)
- `template/before.sh.erb`: Sets up virtual environment and installs open-webui
- `template/script.sh.erb`: Launches Open WebUI server
- `template/after.sh.erb`: Verifies server is running

### Installation Process (`before.sh.erb`)
1. Allocates a unique port using `find_port`
2. Creates virtual environment at `/tmp/${USER}_webui_env`
3. Loads required modules (python, rust, arrow, opencv) **before** creating venv
4. Creates and activates virtual environment
5. Upgrades pip and installs pytz
6. Installs open-webui package via pip (only if not already installed)
7. Exports environment variables for the script

### Server Launch (`script.sh.erb`)
1. Activates the virtual environment from `/tmp`
2. Sets Open WebUI environment variables:
   - `WEBUI_PORT`: Dynamic port from OOD
   - `WEBUI_HOST`: 0.0.0.0 (bind to all interfaces)
   - `WEBUI_DATA_DIR`: Job-specific data directory
   - `WEBUI_AUTH`: false (authentication disabled)
   - `ENABLE_SIGNUP`: false
   - `WEBUI_SECRET_KEY`: Randomly generated
3. Launches Open WebUI server with command-line options:
   - `--host ${WEBUI_HOST}`: Host binding
   - `--port ${WEBUI_PORT}`: Port number
   - `--data-dir ${WEBUI_DATA_DIR}`: Data directory

### Verification (`after.sh.erb`)
1. Waits for the port to become available (120 second timeout)
2. Verifies Open WebUI server is responding
3. Provides connection information

## Configuration

### Resource Requirements
- **Minimum**: 4 CPU cores, 8GB RAM
- **Recommended**: 8+ CPU cores, 16GB+ RAM for better performance
- **Partition**: `gpubase_interac` (interactive jobs)
- **GPU Support**: Optional, can be enabled via form

### Data Storage
- **Working Directory**: `${PWD}/webui-data` (in job directory)
- **Virtual Environment**: `/tmp/${USER}_webui_env` (temporary, per-user)
- **Log File**: `${PWD}/webui.log`

### Open WebUI Settings
- **Mode**: Web-based interface
- **Interface**: Binds to all interfaces (0.0.0.0)
- **Authentication**: Disabled (uses OOD's authentication)
- **Data Persistence**: Chat history saved in job directory

## Environment Variables

The following environment variables are set for Open WebUI:

- `WEBUI_PORT`: Port number (dynamically assigned)
- `WEBUI_HOST`: Host address (0.0.0.0)
- `WEBUI_DATA_DIR`: Data directory path
- `WEBUI_AUTH`: Authentication flag (false)
- `ENABLE_SIGNUP`: Signup enabled flag (false)
- `WEBUI_SECRET_KEY`: Random secret key for sessions
- `WEBUI_NAME`: Application name
- `WEBUI_URL`: Full URL to the instance

## Troubleshooting

### Common Issues

1. **Installation Failures**:
   - Check compute node internet connectivity
   - Verify modules are available (python/3.12.4, rust/1.91.0, arrow, opencv)
   - Ensure sufficient disk space in `/tmp`
   - Check that modules are loaded **before** creating venv

2. **Port Allocation Failures**:
   - Usually indicates system resource constraints
   - Try reducing requested resources

3. **Module Loading Errors**:
   - Verify module names and versions are correct
   - Check that modules are available on compute nodes
   - Ensure modules are loaded before venv creation

4. **Virtual Environment Issues**:
   - Venv is created in `/tmp/${USER}_webui_env`
   - If venv is corrupted, it will be recreated on next job
   - Check `/tmp` disk space availability

5. **Connection Issues**:
   - Verify the server started successfully
   - Check that the port is accessible
   - Review Open WebUI log files in job directory
   - Check that `after.sh.erb` successfully detected the server

### Log Files
- **Open WebUI Logs**: `${PWD}/webui.log`
- **Job Output**: Available in Open On Demand interface
- **System Logs**: Check SLURM and system logs

## Version Information

- **Open WebUI**: Latest version from PyPI (installed via pip)
- **Python Version**: 3.12.4 (automatically loaded)
- **Rust Version**: 1.91.0 (automatically loaded)
- **Installation**: Fully automatic, no manual setup required

## Notes

- The virtual environment is stored in `/tmp`, which is typically cleared on node reboot
- The venv is per-user to avoid conflicts between concurrent jobs
- Open WebUI data (chat history, etc.) is stored in the job directory, not in `/tmp`
- Authentication is disabled since OOD handles user authentication
- The app requires internet access on compute nodes for initial package installation
