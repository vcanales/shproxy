#!/bin/bash

# Detect the operating system
OS="$(uname -s)"

# Default installation directory
INSTALL_DIR="/usr/local/bin"

# Check if /usr/local/bin is suitable, otherwise use ~/bin as a fallback
if [ ! -d "$INSTALL_DIR" ] || [ ! -w "$INSTALL_DIR" ]; then
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

# Script name
SCRIPT_NAME="proxier"

# Location of the current script (where install.sh is located)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if ssh is installed
if ! command -v ssh &> /dev/null; then
    echo "ssh could not be found, please install it first."
    exit 1
fi

# Copy the proxier script to the install directory
cp "${SCRIPT_DIR}/${SCRIPT_NAME}.sh" "${INSTALL_DIR}/${SCRIPT_NAME}"
if [ $? -ne 0 ]; then
    echo "Failed to copy the script to ${INSTALL_DIR}"
    exit 1
fi

# Make the script executable
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
if [ $? -ne 0 ]; then
    echo "Failed to set executable permission on the script"
    exit 1
fi
echo "Installation completed."
echo "Ensure that ${INSTALL_DIR} is in your PATH."
