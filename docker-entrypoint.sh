#!/bin/bash
set -e

LBHOME="/opt/loxberry"

# --- Helper: start a service and report ---
start_service() {
    local name=$1
    echo "[entrypoint] Starting $name..."
    if service "$name" start 2>/dev/null; then
        echo "[entrypoint] $name started successfully."
    else
        echo "[entrypoint] WARNING: Could not start $name."
    fi
}

# Create tmpfs directories that would normally be handled by createtmpfs.service
echo "[entrypoint] Creating tmpfs directories..."
mkdir -p /run/loxberry 2>/dev/null || true
mkdir -p /tmp/loxberry 2>/dev/null || true
if [ -x "$LBHOME/sbin/createtmpfs.sh" ]; then
    $LBHOME/sbin/createtmpfs.sh 2>/dev/null || true
fi

# Start SSH server
start_service ssh

# Start Mosquitto MQTT broker
start_service mosquitto

# Start cron daemon
start_service cron

# Start Samba (optional - may not work well in Docker)
start_service smbd 2>/dev/null || true
start_service nmbd 2>/dev/null || true

# Start VSFTPD
start_service vsftpd 2>/dev/null || true

# Set hostname
hostname loxberry 2>/dev/null || true

# Run LoxBerry init script if available
if [ -x "$LBHOME/sbin/loxberry-init.sh" ]; then
    echo "[entrypoint] Running LoxBerry init script..."
    $LBHOME/sbin/loxberry-init.sh 2>/dev/null || true
fi

# Start Apache web server (main LoxBerry interface)
echo "[entrypoint] Starting Apache2..."
if ! apache2ctl start 2>/dev/null; then
    service apache2 start 2>/dev/null || true
fi

echo "[entrypoint] LoxBerry container is running."
echo "[entrypoint] Web interface available at http://localhost/"
echo "[entrypoint] Default credentials: loxberry / loxberry"

# Keep the container running and tail logs
exec tail -F --retry \
    /var/log/apache2/error.log \
    /var/log/apache2/access.log \
    "$LBHOME/log/system/system.log" \
    2>/dev/null || \
    exec sleep infinity
