# [chaerun/openvpn-monitor][docker-hub-url]

[![Build Status][build-status-image]][build-status-url]
[![Docker Pulls][docker-pulls-image]][docker-hub-url]
[![Docker Stars][docker-stars-image]][docker-hub-url]

Web-based OpenVPN Monitor Docker image. Based on [furlongm/openvpn-monitor](https://github.com/furlongm/openvpn-monitor) and [ruimarinho/docker-openvpn-monitor](https://github.com/ruimarinho/docker-openvpn-monitor) Docker image.

- `amd64` (`x86_64`)
- `arm64` (`aarch64`, `armv8`)
- `armv7`

## What is OpenVPN Monitor?

OpenVPN Monitor is a web-based utility that displays the status of OpenVPN servers. It includes information such as the usernames/hostnames connected, remote and VPN IP addresses, approximate locations (using GeoIP), traffic consumption, and more.

### Key Features of this Image

- **Zero-Config Defaults:** Boots immediately with a built-in Open Source Initiative logo and a default map location centered on Kedonganan, Bali, Indonesia.
- **Auto-Updating GeoIP:** Automatically fetches the latest free DB-IP Lite City database during the Docker build process.
- **Environment Variable Driven:** Dynamically generates the required `.conf` files at runtime via a custom Python entrypoint, meaning no manual volume mapping is required for basic configurations.

---

## Prerequisites: OpenVPN Configuration

Make sure OpenVPN is configured to open the management interface so the Monitor can connect to it. Edit your `server.conf` file and add the following directive (using port `5555` or any port of your preference):

    management 0.0.0.0 5555

---

## Running the Pre-Built Image (Docker Hub)

You can run the latest version directly from Docker Hub. Because this image has sensible defaults baked in, you can launch a functional, out-of-the-box instance pointing to a local OpenVPN server with a single command:

    docker run -d -p 80:80 --name openvpn-monitor \
      -e OPENVPNMONITOR_SITES_0_HOST=192.168.1.100 \
      chaerun/openvpn-monitor

_(Replace `192.168.1.100` with the actual IP address of your OpenVPN server)._

### Advanced Configuration

All settings for OpenVPN Monitor can be dynamically configured via environment variables.

Variables are organized into two groups:

- `OPENVPNMONITOR_DEFAULT_<PROPERTY>`: populates the global `[openvpn-monitor]` section.
- `OPENVPNMONITOR_SITES_<INDEX>_<PROPERTY>`: populates each site section.

_Note: If a property contains underscores (like `datetime_format` or `show_disconnect`), you must pass those properties without the underscore (e.g., `DATETIMEFORMAT`)._

**Example: Running with Custom Locations and Multiple Sites**

    docker run -d --name openvpn-monitor \
      -e OPENVPNMONITOR_DEFAULT_DATETIMEFORMAT="%%Y-%%m-%%d %%H:%%M:%%S" \
      -e OPENVPNMONITOR_DEFAULT_LATITUDE=-37.8136 \
      -e OPENVPNMONITOR_DEFAULT_LONGITUDE=144.9631 \
      -e OPENVPNMONITOR_DEFAULT_MAPS=True \
      -e OPENVPNMONITOR_DEFAULT_MAPSHEIGHT=500 \
      -e OPENVPNMONITOR_DEFAULT_SITE="Global Network" \
      -e OPENVPNMONITOR_SITES_0_ALIAS=UDP \
      -e OPENVPNMONITOR_SITES_0_HOST=192.168.1.50 \
      -e OPENVPNMONITOR_SITES_0_NAME=UDP \
      -e OPENVPNMONITOR_SITES_0_PORT=5555 \
      -e OPENVPNMONITOR_SITES_0_SHOWDISCONNECT=True \
      -e OPENVPNMONITOR_SITES_1_ALIAS=TCP \
      -e OPENVPNMONITOR_SITES_1_HOST=10.0.0.5 \
      -e OPENVPNMONITOR_SITES_1_NAME=TCP \
      -e OPENVPNMONITOR_SITES_1_PORT=5555 \
      -p 80:80 \
      chaerun/openvpn-monitor

The OpenVPN Monitor will now be accessible via http://localhost:80.

#### Overriding the Built-in Logo

This image includes a default `logo.png` located at `/etc/openvpn-monitor/logo.png`. If you want to use your own custom logo, you must mount it into the container and update the environment variable with the absolute path:

    docker run -d -p 80:80 \
      -v /path/to/your/custom-logo.png:/etc/openvpn-monitor/custom-logo.png \
      -e OPENVPNMONITOR_DEFAULT_LOGO=/etc/openvpn-monitor/custom-logo.png \
      chaerun/openvpn-monitor

---

## Building and Running Manually

If you prefer to build the image from source, you can clone the repository and use Docker to build it locally. This will automatically download the latest Furlongm release and the current month's DB-IP database.

### 1. Build the Image

Clone this repository and run the `docker build` command.

    git clone https://github.com/chaerun/docker-openvpn-monitor.git
    cd docker-openvpn-monitor

    # Build the image and tag it locally
    docker build -t my-openvpn-monitor .

### 2. Run your Custom Build

Once the build is complete, you can run it referencing your local tag:

    docker run -d --name my-vpn-monitor \
      -p 8080:80 \
      -e OPENVPNMONITOR_DEFAULT_SITE="My Local Build" \
      -e OPENVPNMONITOR_SITES_0_NAME="Local VPN" \
      -e OPENVPNMONITOR_SITES_0_HOST=192.168.1.100 \
      my-openvpn-monitor

Navigate to http://localhost:8080 to view your locally built monitor.

---

[docker-hub-url]: https://hub.docker.com/r/chaerun/openvpn-monitor
[docker-pulls-image]: https://img.shields.io/docker/pulls/chaerun/openvpn-monitor
[docker-stars-image]: https://img.shields.io/docker/stars/chaerun/openvpn-monitor
[build-status-image]: https://github.com/chaerun/docker-openvpn-monitor/actions/workflows/main.yml/badge.svg
[build-status-url]: https://github.com/chaerun/docker-openvpn-monitor/actions/workflows/main.yml
