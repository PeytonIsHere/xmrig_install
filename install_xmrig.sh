#!/bin/bash

# Script to install XMRig with predefined settings and set up terminal monitoring
# Created: 2025-03-15 00:31:05 UTC

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo: sudo $0"
  exit 1
fi

echo "Starting XMRig installation script..."

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y wget tar build-essential cmake libuv1-dev libssl-dev libhwloc-dev tmux htop

# Create directory for XMRig in current directory
echo "Creating XMRig directory..."
INSTALL_DIR="$(pwd)/xmrig"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Download latest XMRig release for Linux x64
echo "Downloading XMRig..."
LATEST_RELEASE_URL=$(wget -qO- https://api.github.com/repos/xmrig/xmrig/releases/latest | grep "browser_download_url.*xmrig-.*-linux-x64.tar.gz" | cut -d '"' -f 4)
if [ -z "$LATEST_RELEASE_URL" ]; then
  # Fallback to a known version if API fails
  LATEST_RELEASE_URL="https://github.com/xmrig/xmrig/releases/download/v6.18.1/xmrig-6.18.1-linux-x64.tar.gz"
fi
wget -O xmrig.tar.gz "$LATEST_RELEASE_URL" || {
  echo "Failed to download XMRig. Exiting."
  exit 1
}

# Extract XMRig
echo "Extracting XMRig..."
tar -xzf xmrig.tar.gz --strip-components=1 || {
  echo "Failed to extract XMRig. Exiting."
  exit 1
}
rm xmrig.tar.gz

# Create configuration file with complete predefined settings
echo "Creating configuration file..."
cat > config.json << 'EOL'
{
    "api": {
        "id": null,
        "worker-id": null
    },
    "http": {
        "enabled": false,
        "host": "127.0.0.1",
        "port": 0,
        "access-token": null,
        "restricted": true
    },
    "autosave": true,
    "background": false,
    "colors": true,
    "title": true,
    "randomx": {
        "init": -1,
        "init-avx2": -1,
        "mode": "auto",
        "1gb-pages": false,
        "rdmsr": true,
        "wrmsr": true,
        "cache_qos": false,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    },
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": false,
        "hw-aes": null,
        "priority": null,
        "memory-pool": false,
        "yield": true,
        "max-threads-hint": 100,
        "asm": true,
        "argon2-impl": null,
        "cn/0": false,
        "cn-lite/0": false
    },
    "opencl": {
        "enabled": false,
        "cache": true,
        "loader": null,
        "platform": "AMD",
        "adl": true,
        "cn/0": false,
        "cn-lite/0": false
    },
    "cuda": {
        "enabled": false,
        "loader": null,
        "nvml": true,
        "cn/0": false,
        "cn-lite/0": false
    },
    "donate-level": 1,
    "donate-over-proxy": 1,
    "log-file": null,
    "pools": [
        {
            "algo": null,
            "coin": null,
            "url": "pool.supportxmr.com:3333",
            "user": "48peM4MTjhBBkwBbkjg5uh5yZvqBHGnVedo4LJs3JtqpjB31uT4NhXSZzGAgUwkcHob56f9ANwQbcEuFAP6qSx4R8LEGLV7",
            "pass": "x",
            "rig-id": null,
            "nicehash": false,
            "keepalive": false,
            "enabled": true,
            "tls": false,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "submit-to-origin": false
        }
    ],
    "print-time": 60,
    "health-print-time": 60,
    "dmi": true,
    "retries": 5,
    "retry-pause": 5,
    "syslog": false,
    "tls": {
        "enabled": false,
        "protocols": null,
        "cert": null,
        "cert_key": null,
        "ciphers": null,
        "ciphersuites": null,
        "dhparam": null
    },
    "dns": {
        "ipv6": false,
        "ttl": 30
    },
    "user-agent": null,
    "verbose": 0,
    "watch": true,
    "pause-on-battery": false,
    "pause-on-active": false
}
EOL

# Create script to run XMRig and htop in tmux
echo "Creating startup script..."
cat > start_mining.sh << EOL
#!/bin/bash
cd "$INSTALL_DIR"

# Kill any existing tmux sessions with this name
tmux kill-session -t mining 2>/dev/null || true

# Start a new tmux session
tmux new-session -d -s mining

# Split the window horizontally
tmux split-window -h -t mining

# Run XMRig in the left pane
tmux send-keys -t mining:0.0 "$INSTALL_DIR/xmrig" C-m

# Run htop in the right pane
tmux send-keys -t mining:0.1 "htop" C-m

# Attach to the session
tmux attach-session -t mining
EOL

# Make the startup script executable
chmod +x start_mining.sh
chmod +x xmrig

echo "Installation complete!"
echo "IMPORTANT: Edit $INSTALL_DIR/config.json to set your Monero wallet address"
echo "Starting mining session..."

# Try to start mining immediately
bash "$INSTALL_DIR/start_mining.sh" || {
  echo "Failed to start mining automatically."
  echo "You can manually start it with: $INSTALL_DIR/start_mining.sh"
}
