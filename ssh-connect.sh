#!/bin/bash

# Default parameters
PROXY_PORT=""
KEY_PATH=""
SSH_LOG=""
SSH_SOCKS_PROXY=""
PROXY_USER=""
PROXY_HOST=""
PROXY_KEY=""

# Parse command line options
while getopts "p:k:l:s:u:h:K:" opt; do
  case $opt in
    p) PROXY_PORT=$OPTARG ;;
    k) KEY_PATH=$OPTARG ;;
    l) SSH_LOG=$OPTARG ;;
    s) SSH_SOCKS_PROXY=$OPTARG ;;
    u) PROXY_USER=$OPTARG ;;
    h) PROXY_HOST=$OPTARG ;;
    K) PROXY_KEY=$OPTARG ;;
    *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Check required parameters
if [[ -z "$PROXY_PORT" || -z "$KEY_PATH" || -z "$SSH_LOG" || -z "$SSH_SOCKS_PROXY" || -z "$PROXY_USER" || -z "$PROXY_HOST" ]]; then
  echo "Missing required parameters."
  echo "Usage: $0 -p PROXY_PORT -k KEY_PATH -l SSH_LOG -s SSH_SOCKS_PROXY -u PROXY_USER -h PROXY_HOST -K PROXY_KEY"
  exit 1
fi

# Determine SSH options for known hosts file
if [ -z "$PROXY_KEY" ]; then
    KNOWN_HOSTS_OPTION="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    echo "Warning: Proxy host key is not set. SSH will connect without verifying the host identity."
    echo "It is recommended to set a proxy host key to avoid potential security risks."
elif [ ! -f "$PROXY_KEY" ]; then
    # Proxy key is set but file does not exist
    KNOWN_HOSTS_OPTION="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    echo "Warning: Specified proxy host key file '$PROXY_KEY' does not exist. SSH will connect without verifying the host identity."
    echo "Please check the path to your proxy host key file."
else
    KNOWN_HOSTS_OPTION="-o UserKnownHostsFile=\"$PROXY_KEY\""
fi

# Establish SSH tunnel
ssh -NvD "$PROXY_PORT" \
    -M -S "$SSH_SOCKS_PROXY" \
    -fnT -i "$KEY_PATH" \
    $KNOWN_HOSTS_OPTION \
    -o "ServerAliveInterval=60" \
    -p 22 \
    -vvv \
    -E "$SSH_LOG" \
    "$PROXY_USER@$PROXY_HOST"