
# Proxier

Proxier is a command-line utility designed to manage SSH tunnels with SOCKS proxy configuration.

## Installation

### Steps

1. Clone the repository or download the source files to your local machine.
2. Navigate to the directory containing `install.sh`.
3. Run the installation script:

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

This script will set up a symbolic link in `/usr/local/bin` or `~/bin` if the former isn't writable. Make sure that the chosen bin directory is in your system's PATH.

## Configuration

Run the `proxier init` command to start the interactive configuration setup:

```bash
proxier init
```

You'll be prompted to enter the following details:

- **Proxy User**: Username for SSH connection.
- **Proxy Host**: Hostname or IP address of the proxy server.
- **Proxy Port**: Port number for the SSH tunnel.
- **SSH Key Path**: Path to your SSH private key.
- **Proxy Host Key**: (Optional) Path to your proxy's host key for SSH.
- **PAC File URL**: (Optional) URL to your PAC file for automatic proxy configuration.

These settings will be saved to `.env` in the script's directory.

## Usage

### Starting the Proxy

To start the proxy, simply run:

```bash
proxier start
```

If you're running the script for the first time or your configuration has changed, you may need to initialize or reconfigure your settings using `proxier init`.

### Stopping the Proxy

To stop the proxy, use:

```bash
proxier stop
```

### Checking Status

To check whether the proxy is currently running:

```bash
proxier status
```

### Viewing Logs

To view and follow the logs in real-time:

```bash
proxier logs
```

## Contributing

Contributions to Proxier are welcome! Please feel free to fork the repository, make your changes, and submit a pull request.
