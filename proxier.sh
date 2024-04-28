# Define the location of environment and related files
# Cross-platform robust way to find the source directory of the script
__dirname="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -L "${BASH_SOURCE[0]}" ] && __dirname="$(dirname "$(readlink "${BASH_SOURCE[0]}")")"

ENV_PATH="$__dirname/.env"
SSH_LOG="$__dirname/ssh.log"
SSH_SOCKS_PROXY="$__dirname/proxier-socks"

# Function to load existing environment variables from .env
load_env() {
    if [ -f "$ENV_PATH" ]; then
        echo "Loading existing environment settings..."
        source "$ENV_PATH"
    fi
}

init_env() {
    echo "Initializing environment configuration..."

    # Load existing environment variables, if any
    load_env

    # Read or set default values
    read -p "Enter proxy user [current: ${PROXY_USER:-'not set'}]: " input
    PROXY_USER=${input:-${PROXY_USER}}

    read -p "Enter proxy host [current: ${PROXY_HOST:-'not set'}]: " input
    PROXY_HOST=${input:-${PROXY_HOST}}

    read -p "Enter proxy port [current: ${PROXY_PORT:-'not set'}]: " input
    PROXY_PORT=${input:-${PROXY_PORT}}

    read -p "Enter the path to your SSH key [current: ${KEY_PATH:-'not set'}, default: ~/.ssh/id_rsa]: " input
    KEY_PATH=${input:-${KEY_PATH:-~/.ssh/id_rsa}}

    read -p "Enter the path to your proxy host key [current: ${PROXY_KEY:-'not set'}]: " input
    PROXY_KEY=${input:-${PROXY_KEY}}

    read -p "Enter the URL to the PAC file [current: ${PAC_FILE_URL:-'not set'}]: " input
    PAC_FILE_URL=${input:-${PAC_FILE_URL}}

    # Confirmation to save settings
    echo
    echo "Configuration to save:"
    echo "PROXY_USER=${PROXY_USER}"
    echo "PROXY_HOST=${PROXY_HOST}"
    echo "PROXY_PORT=${PROXY_PORT}"
    echo "KEY_PATH=${KEY_PATH}"
    echo "PROXY_KEY=${PROXY_KEY}"
    echo "PAC_FILE_URL=${PAC_FILE_URL}"
    echo

    read -p "Save these settings? [Y/n] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] || [[ -z "$response" ]]; then
        echo "PROXY_USER='${PROXY_USER}'" > "$ENV_PATH"
        echo "PROXY_HOST='${PROXY_HOST}'" >> "$ENV_PATH"
        echo "PROXY_PORT='${PROXY_PORT}'" >> "$ENV_PATH"
        echo "KEY_PATH='${KEY_PATH}'" >> "$ENV_PATH"
        echo "PAC_FILE_URL='${PAC_FILE_URL}'" >> "$ENV_PATH"
        if [ -n "$PROXY_KEY" ]; then
            echo "PROXY_KEY='${PROXY_KEY}'" >> "$ENV_PATH"
        else
            # Use sed compatible with both GNU and BSD versions
            sed -i.bak '/PROXY_KEY/d' "$ENV_PATH" && rm "$ENV_PATH.bak"
        fi
        echo "Configuration saved to $ENV_PATH"
    else
        echo "Configuration not saved."
    fi
}


# Read the configuration from .env file
read_config() {
    if [ ! -f "$ENV_PATH" ]; then
        touch "$ENV_PATH"
    fi
    cat "$ENV_PATH"
}

# Start the proxy
start() {
    load_env
    if [ -z "$PROXY_HOST" ] || [ -z "$PROXY_PORT" ] || [ -z "$KEY_PATH" ] || [ -z "$PROXY_USER" ]; then
        echo "Configuration variables are missing. Please run the 'proxier init' command to set them."
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

    bash ssh-connect.sh -p "$PROXY_PORT" -k "$KEY_PATH" -l "$SSH_LOG" -s "$SSH_SOCKS_PROXY" -u "$PROXY_USER" -h "$PROXY_HOST" -K "$PROXY_KEY" &
    sleep 1 # Allows the system to handle the output buffer before moving on
    disown

    bash "$__dirname/status-checker.sh" &
    sleep 1 # Allows the system to handle the output buffer before moving on
    disown
}

# Stop the proxy
stop() {
    pkill -f "ssh -NvD $PROXY_PORT"
    rm -f "$SSH_SOCKS_PROXY"
    rm -f "$SSH_LOG"
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
    if [ -f "$SSH_LOG" ]; then
        echo "Press 'Ctrl-C' to stop following the log, and 'q' to quit viewing the log."
        less +F "$SSH_LOG"
    else
        echo "Log file does not exist: $SSH_LOG"
    fi
}

# Handle script arguments to call functions
case "$1" in
    init)
        init_env
        ;;
    read_config)
        read_config
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
        echo "Usage: $0 {init|read_config|start|stop|status|logs} [options]"
        exit 1
esac
