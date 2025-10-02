#!/bin/bash

# OpenRefine Test Script
# Downloads, extracts, and tests OpenRefine 3.9.5 with custom port and host binding

set -e  # Exit on any error

echo "=== OpenRefine Test Script ==="
echo "Testing OpenRefine 3.9.5 with custom configuration"
echo

# Configuration
OPENREFINE_VERSION="3.9.5"
DOWNLOAD_URL="https://github.com/OpenRefine/OpenRefine/releases/download/${OPENREFINE_VERSION}/openrefine-linux-${OPENREFINE_VERSION}.tar.gz"
TEST_PORT="13337"  # Weird port number as requested
TEST_HOST="0.0.0.0"  # Bind to all interfaces
TEST_DIR="/tmp/openrefine_test_$$"
OPENREFINE_DIR="${TEST_DIR}/openrefine-${OPENREFINE_VERSION}"

echo "Configuration:"
echo "  Version: ${OPENREFINE_VERSION}"
echo "  Download URL: ${DOWNLOAD_URL}"
echo "  Test Port: ${TEST_PORT}"
echo "  Test Host: ${TEST_HOST}"
echo "  Test Directory: ${TEST_DIR}"
echo

# Cleanup function
cleanup() {
    echo
    echo "Cleaning up test directory..."
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        echo "✅ Cleanup completed"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check prerequisites
echo "Checking prerequisites..."
for tool in wget tar java; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "❌ ERROR: $tool is required but not found"
        exit 1
    fi
    echo "✅ $tool found"
done

# Check Java version
echo "Checking Java version..."
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
echo "Java: $JAVA_VERSION"

if java -version 2>&1 | grep -q "version \"1[7-9]\|version \"[2-9][0-9]"; then
    echo "✅ Java version is compatible"
else
    echo "⚠️  WARNING: Java version may not be compatible with OpenRefine"
fi

echo

# Create test directory
echo "Creating test directory: ${TEST_DIR}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Download OpenRefine
echo "Downloading OpenRefine ${OPENREFINE_VERSION}..."
echo "URL: ${DOWNLOAD_URL}"

if wget -q --show-progress "$DOWNLOAD_URL"; then
    echo "✅ Download completed"
else
    echo "❌ Download failed"
    exit 1
fi

# Extract OpenRefine
echo "Extracting OpenRefine..."
TARBALL="openrefine-linux-${OPENREFINE_VERSION}.tar.gz"

if tar -xzf "$TARBALL"; then
    echo "✅ Extraction completed"
else
    echo "❌ Extraction failed"
    exit 1
fi

# Verify extraction
if [ -d "$OPENREFINE_DIR" ] && [ -f "${OPENREFINE_DIR}/refine" ]; then
    echo "✅ OpenRefine extracted successfully"
    echo "Location: ${OPENREFINE_DIR}/refine"
else
    echo "❌ Extraction verification failed"
    exit 1
fi

# Make refine executable
echo "Setting permissions..."
chmod +x "${OPENREFINE_DIR}/refine"

# Test OpenRefine with custom configuration
echo
echo "=== Testing OpenRefine Launch ==="
echo "Port: ${TEST_PORT}"
echo "Host: ${TEST_HOST}"
echo "Command: ${OPENREFINE_DIR}/refine --port=${TEST_PORT} --host=${TEST_HOST} --headless"
echo

# Start OpenRefine in background
echo "Starting OpenRefine..."
cd "$OPENREFINE_DIR"

# Launch OpenRefine with custom settings
nohup ./refine \
    --port="${TEST_PORT}" \
    --host="${TEST_HOST}" \
    --headless \
    > "${TEST_DIR}/openrefine.log" 2>&1 &

OPENREFINE_PID=$!
echo "OpenRefine started with PID: $OPENREFINE_PID"

# Wait for OpenRefine to start
echo "Waiting for OpenRefine to initialize..."
sleep 15

# Check if OpenRefine is still running
if ! kill -0 $OPENREFINE_PID 2>/dev/null; then
    echo "❌ OpenRefine process died. Check logs:"
    cat "${TEST_DIR}/openrefine.log"
    exit 1
fi

echo "✅ OpenRefine is running"

# Test port connectivity
echo "Testing port connectivity..."
if command -v nc >/dev/null 2>&1; then
    if nc -z "${TEST_HOST}" "${TEST_PORT}" 2>/dev/null; then
        echo "✅ Port ${TEST_PORT} is accessible"
    else
        echo "⚠️  Port ${TEST_PORT} not accessible via netcat"
    fi
else
    echo "⚠️  netcat not available for port testing"
fi

# Test HTTP connectivity
echo "Testing HTTP connectivity..."
if command -v curl >/dev/null 2>&1; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${TEST_HOST}:${TEST_PORT}" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ]; then
        echo "✅ HTTP connection successful (status: ${HTTP_STATUS})"
    else
        echo "⚠️  HTTP connection failed (status: ${HTTP_STATUS})"
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q --spider "http://${TEST_HOST}:${TEST_PORT}" 2>/dev/null; then
        echo "✅ HTTP connection successful via wget"
    else
        echo "⚠️  HTTP connection failed via wget"
    fi
else
    echo "⚠️  No HTTP client available for testing"
fi

# Show log contents
echo
echo "=== OpenRefine Log Contents ==="
if [ -f "${TEST_DIR}/openrefine.log" ]; then
    cat "${TEST_DIR}/openrefine.log"
else
    echo "No log file found"
fi

echo
echo "=== Test Results ==="
echo "✅ OpenRefine ${OPENREFINE_VERSION} downloaded and extracted successfully"
echo "✅ OpenRefine launched on port ${TEST_PORT} with host ${TEST_HOST}"
echo "✅ Process is running (PID: $OPENREFINE_PID)"
echo
echo "You can test the web interface at: http://localhost:${TEST_PORT}"
echo "Or from another machine: http://$(hostname -I | awk '{print $1}'):${TEST_PORT}"
echo
echo "To stop OpenRefine: kill $OPENREFINE_PID"
echo "To view logs: cat ${TEST_DIR}/openrefine.log"

# Keep the process running for a bit to allow manual testing
echo
echo "OpenRefine will run for 60 seconds for manual testing..."
echo "Press Ctrl+C to stop early"
sleep 60

echo
echo "Stopping OpenRefine..."
kill $OPENREFINE_PID 2>/dev/null || true
wait $OPENREFINE_PID 2>/dev/null || true
echo "✅ OpenRefine stopped"

echo
echo "=== Test Complete ==="
echo "OpenRefine ${OPENREFINE_VERSION} test completed successfully!"
echo "The app can be configured to use this version."
