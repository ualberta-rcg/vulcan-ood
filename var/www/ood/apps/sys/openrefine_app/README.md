# OpenRefine App for Open On Demand

This directory contains the OpenRefine application configuration for Open On Demand, allowing users to run OpenRefine instances on the Vulcan HPC cluster.

## Overview

OpenRefine is a powerful tool for working with messy data: cleaning it; transforming it from one format into another; extending it with web services; and linking it to databases. This Open On Demand app provides a web-based interface to launch OpenRefine instances on compute nodes.

## Features

- **Dynamic Port Allocation**: Each OpenRefine instance gets a unique port automatically
- **Resource Management**: Users can specify CPU cores and memory requirements
- **Data Persistence**: Projects are saved in the user's home directory
- **Secure Access**: Each instance runs in an isolated environment
- **Web Interface**: Easy-to-use web interface for launching and accessing OpenRefine

## Prerequisites

Before using this app, ensure that:

1. **Java Runtime Environment**: Java 8 or higher is available on the compute nodes
2. **OpenRefine Installation**: OpenRefine is installed and accessible via:
   - System-wide installation at `/opt/openrefine/refine`
   - User installation at `${HOME}/openrefine/refine`
   - Available in the system PATH as `openrefine`

## Installation

1. **Download OpenRefine** (if not already installed):
   ```bash
   # Download the latest version from https://openrefine.org/download.html
   wget https://github.com/OpenRefine/OpenRefine/releases/download/3.7.7/openrefine-linux-3.7.7.tar.gz
   tar -xzf openrefine-linux-3.7.7.tar.gz
   mv openrefine-3.7.7 ~/openrefine
   ```

2. **Make OpenRefine executable**:
   ```bash
   chmod +x ~/openrefine/refine
   ```

3. **Verify Java is available**:
   ```bash
   module load java/17.0.6
   java -version
   ```

## Usage

1. **Access the App**: Navigate to the OpenRefine app in the Open On Demand dashboard
2. **Configure Resources**: Set your desired CPU cores and memory requirements
3. **Submit Job**: Click "Launch" to start your OpenRefine instance
4. **Access OpenRefine**: Once the job starts, click "Open OpenRefine" to access your instance

## Configuration Files

- `manifest.yml`: App metadata and description
- `form.yml.erb`: Job submission form configuration
- `template/before.sh.erb`: Pre-job setup script (port allocation, environment setup)
- `template/script.sh.erb`: Main script that launches OpenRefine
- `template/after.sh.erb`: Post-launch verification script
- `view.html.erb`: User interface template

## Technical Details

### Port Management
- Uses Open On Demand's `find_port` function to allocate available ports
- Each instance runs on a unique port (e.g., `/node/hostname/port/`)
- Port allocation is handled automatically by the system

### Resource Requirements
- **Minimum**: 2 CPU cores, 4GB RAM
- **Recommended**: 4+ CPU cores, 8GB+ RAM for large datasets
- **Java Memory**: Configured with `-Xmx4g -Xms1g` by default

### Data Storage
- Projects are stored in `${OPENREFINE_WORKDIR}` (job-specific directory)
- Working directory: `${PWD}/openrefine-data`
- Log file: `${PWD}/openrefine.log`

### Security
- Runs in headless mode (`--headless`)
- No authentication required (single-user per instance)
- Isolated environment per job
- Data directory permissions are user-specific

## Troubleshooting

### Common Issues

1. **"OpenRefine not found" error**:
   - Ensure OpenRefine is installed and accessible
   - Check that the `refine` executable has proper permissions
   - Verify the installation path

2. **Port allocation failures**:
   - Usually indicates system resource constraints
   - Try reducing requested resources or waiting for other jobs to complete

3. **Java errors**:
   - Ensure Java module is loaded: `module load java/17.0.6`
   - Check Java version compatibility with OpenRefine

4. **Memory issues**:
   - Increase requested memory in the job form
   - Consider processing smaller datasets
   - Monitor system memory usage

### Log Files

Check these log files for debugging:
- `${OPENREFINE_LOG_FILE}`: OpenRefine application logs
- Job output logs in the Open On Demand interface
- System logs for port allocation and resource management

## Customization

### Memory Configuration
To modify Java memory settings, edit `template/before.sh.erb`:
```bash
export JAVA_OPTS="-Xmx8g -Xms2g ..."  # Increase memory allocation
```

### Additional Java Options
Add custom Java options in `template/before.sh.erb`:
```bash
export JAVA_OPTS="$JAVA_OPTS -Dcustom.property=value"
```

### OpenRefine Extensions
To add OpenRefine extensions, modify `template/script.sh.erb` to include extension loading.

## Support

For issues related to:
- **Open On Demand**: Contact your system administrator
- **OpenRefine**: Visit [OpenRefine Documentation](https://openrefine.org/docs/)
- **Vulcan Cluster**: Contact Alliance Canada support

## Version Information

- **OpenRefine Version**: 3.7.7+ (configurable)
- **Java Requirement**: 8+ (tested with Java 17)
- **Open On Demand**: Compatible with OOD 2.0+
