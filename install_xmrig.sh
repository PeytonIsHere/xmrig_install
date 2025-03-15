#!/bin/bash

# Script to install XMRig with predefined settings and set up terminal monitoring
# Created: 2025-03-15
# User: PeytonIsHere

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo: sudo $0"
  exit 1
fi

# Get the actual username (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

echo "Starting XMRig installation script..."

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y wget tar build-essential cmake libuv1-dev libssl-dev libhwloc-dev tmux htop

# Create directory for XMRig
echo "Creating XMRig directory..."
mkdir -p $ACTUAL_HOME/xmrig
cd $ACTUAL_HOME/xmrig

# Set ownership
chown -R $ACTUAL_USER:$ACTUAL_USER $ACTUAL_HOME/xmrig

# Download latest XMRig release for Linux x64
echo "Downloading XMRig..."
LATEST_RELEASE_URL=$(wget -qO- https://api.github.com/repos/xmrig/xmrig/releases/latest | grep "browser_download_url.*xmrig-.*-linux-x64.tar.gz" | cut -d '"' -f 4)
wget -O xmrig.tar.gz "$LATEST_RELEASE_URL"

# Extract XMRig
echo "Extracting XMRig..."
tar -xzf xmrig.tar.gz --strip-components=1
rm xmrig.tar.gz

# Create configuration file with predefined settings
echo "Creating configuration file..."
cat > config.json << EOL
{
    "autosave": true,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "url": "pool.supportxmr.com:3333",
            "user": "YOUR_MONERO_WALLET_ADDRESS",
            "pass": "x",
            "keepalive": true,
            "tls": false
        }
    ]
}
EOL

# Create script to run XMRig and htop in tmux
echo "Creating startup script..."
cat > start_mining.sh << EOL
#!/bin/bash
cd $ACTUAL_HOME/xmrig

# Kill any existing tmux sessions with this name
tmux kill-session -t mining 2>/dev/null || true

# Start a new tmux session
tmux new-session -d -s mining

# Split the window horizontally
tmux split-window -h -t mining

# Run XMRig in the left pane
tmux send-keys -t mining:0.0 "./xmrig" C-m

# Run htop in the right pane
tmux send-keys -t mining:0.1 "htop" C-m

# Attach to the session
tmux attach-session -t mining
EOL

# Make the startup script executable
chmod +x start_mining.sh
chown $ACTUAL_USER:$ACTUAL_USER start_mining.sh

# Set proper permissions for all files
chown -R $ACTUAL_USER:$ACTUAL_USER $ACTUAL_HOME/xmrig

echo "Installation complete!"
echo "IMPORTANT: Edit $ACTUAL_HOME/xmrig/config.json to set your Monero wallet address"
echo "Starting mining session..."

# Start mining immediately as the actual user
sudo -u $ACTUAL_USER bash -c "$ACTUAL_HOME/xmrig/start_mining.sh"