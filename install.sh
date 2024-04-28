#!/bin/bash

# Detect the operating system
OS="$(uname -s)"

# Default installation directory, generally accessible in PATH
INSTALL_DIR="/usr/local/bin"

# Check if /usr/local/bin is suitable, otherwise use ~/bin as a fallback
if [ ! -d "$INSTALL_DIR" ] || [ ! -w "$INSTALL_DIR" ]; then
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
    echo "Created $INSTALL_DIR as it was not found or was not writable."
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

# Create a symbolic link to the script in the installation directory
ln -sf "${SCRIPT_DIR}/${SCRIPT_NAME}.sh" "${INSTALL_DIR}/${SCRIPT_NAME}"
if [ $? -ne 0 ]; then
    echo "Failed to create a symbolic link in ${INSTALL_DIR}"
    exit 1
fi

echo "Symbolic link created for ${SCRIPT_NAME}.sh in ${INSTALL_DIR}"

# Ensure the script is executable
chmod +x "${SCRIPT_DIR}/${SCRIPT_NAME}.sh"
if [ $? -ne 0 ]; then
    echo "Failed to set executable permission on the script"
    exit 1
fi

echo "Installation completed. You can now run the script using '${SCRIPT_NAME}' from anywhere."
echo "Ensure that ${INSTALL_DIR} is in your PATH."
