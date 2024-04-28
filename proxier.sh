#!/bin/bash

# Define the location of environment and related files
__dirname="$(dirname "$(readlink -f "$0")")"
envPath="$__dirname/.env"
sshLog="$__dirname/ssh.log"
sshSocksProxy="$__dirname/proxier-socks"
proxyKey="$__dirname/ProxyHostKey.pub"

# Function to load environment variables
init_env() {
    if [ ! -f "$envPath" ]; then
        touch "$envPath"
    fi
    export $(grep -v '^#' "$envPath" | xargs)
}

# Read the configuration from .env file
read_config() {
    if [ ! -f "$envPath" ]; then
        touch "$envPath"
    fi
    cat "$envPath"
}

# Save configuration to the .env file
save_config() {
    for var in "$@"; do
        echo "$var" >> "$envPath"
    done
    sort -u "$envPath" -o "$envPath"
}

# Start the proxy
start() {
    init_env
    if [ -z "$PROXY_HOST" ] || [ -z "$PROXY_PORT" ] || [ -z "$KEY_PATH" ] || [ -z "$PROXY_USER" ]; then
        echo "Configuration variables are missing. Please run the 'proxier config' command to set them."
        return 1
    fi

    if [ "$1" = "restart" ]; then
        stop
    else
        if status; then
            return 1
        fi
    fi

    if [ "$(uname)" = "Darwin" ]; then
        # @TODO: Update the network service name if needed
        networksetup -setautoproxyurl "Wi-Fi" "$PAC_FILE_URL" || {
            echo "Error setting automatic proxy config on; please do so manually."
            return 1
        }
    fi

    echo "Starting proxy..."

    ssh -NvD "$PROXY_PORT" \
        -M -S "$sshSocksProxy" \
        -fnT -i "$KEY_PATH" \
        -o "UserKnownHostsFile=$proxyKey" \
        -o "ServerAliveInterval=60" \
        -p 22 \
        -vvv \
        -E "$sshLog" \
        "${PROXY_USER}@${PROXY_HOST}" &

    disown

    bash "$__dirname/status-checker.sh" &
    disown
}

# Stop the proxy
stop() {
    pkill -f "ssh -NvD $PROXY_PORT"
    rm -f "$sshSocksProxy"
    rm -f "$sshLog"
    crontab -l | grep -v "status-checker.sh" | crontab -
    if [ "$(uname)" = "Darwin" ]; then
        networksetup -setautoproxystate "Wi-Fi" off || {
            echo "Could not turn off automatic proxy config; please do so manually."
            return 1
        }
    fi
}

# Check proxy status
status() {
    if pgrep -f "ssh -NvD $PROXY_PORT" > /dev/null; then
        echo "Proxy is running."
        return 0
    else
        echo "Proxy is not running."
        return 1
    fi
}

# Tail logs
logs() {
    tail -f "$sshLog"
}

# Handle script arguments to call functions
case "$1" in
    init_env)
        init_env
        ;;
    read_config)
        read_config
        ;;
    save_config)
        shift
        save_config "$@"
        ;;
    start)
        start "$2"
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    *)
        echo "Usage: $0 {init_env|read_config|save_config|start|stop|status|logs} [options]"
        exit 1
esac
