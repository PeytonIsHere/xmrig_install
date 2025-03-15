# XMRig Monero Mining Setup

## Overview

This repository contains a script to easily set up XMRig for mining Monero cryptocurrency on Ubuntu systems. The script automatically installs XMRig with a predefined configuration and sets up a split terminal view showing both the mining process and system resource usage.

## Installation

### Setup Instructions

1. Download the installation script:
   ```bash
   wget https://github.com/PeytonIsHere/xmrig_install/blob/main/install_xmrig.sh
   ```

2. Make it executable:
   ```bash
   chmod +x install_xmrig.sh
   ```

3. Run the script with sudo:
   ```bash
   sudo ./install_xmrig.sh
   ```

## Features

- Automatically downloads and installs the latest version of XMRig
- Sets up a split terminal view using tmux:
  - Left side: XMRig mining process
  - Right side: htop system monitor
- Includes a pre-configured setup for the SupportXMR mining pool
- Easy to start and stop mining
