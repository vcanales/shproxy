#!/bin/bash

# Define the location of environment and related files
# Cross-platform robust way to find the source directory of the script
__dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -L "${BASH_SOURCE[0]}" ] && __dirname="$(dirname "$(readlink "${BASH_SOURCE[0]}")")"

# Load environment variables
if [ -f "${__dirname}/.env" ]; then
  export $(grep -v '^#' "${__dirname}/.env" | xargs)
fi

# Define file paths from the environment or use defaults
SSH_SOCKS_PROXY="${__dirname}/${SSH_SOCKS_PROXY:-proxier-socks}"
KEY_PATH="${KEY_PATH:-key}"
PROXY_KEY="${__dirname}/${PROXY_KEY:-ProxyHostKey.pub}"
SSH_LOG="${__dirname}/${SSH_LOG:-ssh.log}"
PROXY_USER="${PROXY_USER}"
PROXY_HOST="${PROXY_HOST}"
PROXY_PORT="${PROXY_PORT}"

# Print values if debug is enabled
if [ "$DEBUG" = "true" ]; then
  echo "__dirname: $__dirname"
  echo "SSH_SOCKS_PROXY: $SSH_SOCKS_PROXY"
  echo "KEY_PATH: $KEY_PATH"
  echo "PROXY_KEY: $PROXY_KEY"
  echo "SSH_LOG: $SSH_LOG"
  echo "PROXY_USER: $PROXY_USER"
  echo "PROXY_HOST: $PROXY_HOST"
  echo "PROXY_PORT: $PROXY_PORT"
fi

# Function to restart the SSH tunnel
function restart_ssh_tunnel {
  # Kill existing SSH process if any
  pkill -f "ssh -NvD $PROXY_PORT"

  # Start new SSH tunnel process
  bash $__diranme/ssh-connect.sh -p "$PROXY_PORT" -k "$KEY_PATH" -l "$SSH_LOG" -s "$SSH_SOCKS_PROXY" -u "$PROXY_USER" -h "$PROXY_HOST" -K "$PROXY_KEY" &
  [ -n $DEBUG == true ] && echo "SSH tunnel restarted."
}

# Function to check if the SSH process is running and if the connection is active
function check_ssh_connection {
  local ssh_check=$(ssh -O check -S "$SSH_SOCKS_PROXY" "${PROXY_USER}@${PROXY_HOST}" 2>&1)
  if [[ "$ssh_check" == *"Master running"* ]]; then
    [ "$DEBUG" = "true" ] && echo "SSH connection is active."
  else
    [ "$DEBUG" = "true" ] && echo "SSH connection is not active."
    restart_ssh_tunnel
  fi
}

# Conditional execution based on OS type
if [ "$(uname)" == "Linux" ]; then
  # Linux platforms can use flock
  (
    flock -n 9 || exit 1

    # Check SSH connection
    check_ssh_connection

    # Add a cron job to run this script every minute if it's not already added
    (crontab -l 2>/dev/null | grep -q "$(basename "$0")") || (crontab -l 2>/dev/null; echo "* * * * * $__dirname/$(basename "$0")") | crontab -

  ) 9>$__dirname/proxier.lock
elif [ "$(uname)" == "Darwin" ]; then
  # macOS uses a lock directory approach
  LOCK_DIR="$__dirname/proxier.lock"
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    [ -n $DEBUG == true ] && echo "Lock directory created successfully."

    # Check SSH connection
    check_ssh_connection

    # Add a cron job to run this script every minute if it's not already added
    (crontab -l 2>/dev/null | grep -q "$(basename "$0")") || (crontab -l 2>/dev/null; echo "* * * * * $__dirname/$(basename "$0")") | crontab -

    # Remove lock directory after script execution
    rmdir "$LOCK_DIR"
  else
    [ -n $DEBUG == true ] && echo "Script is already running."
  fi
fi
