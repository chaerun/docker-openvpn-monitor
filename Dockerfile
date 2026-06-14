# ----------------------------------------------------
# Stage 1: Download release source and build JS assets
# ----------------------------------------------------
FROM node:18-slim AS builder

ARG VERSION=2.0.3

RUN apt-get update && apt-get install -y wget tar && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN wget -qO- https://github.com/furlongm/openvpn-monitor/archive/refs/tags/${VERSION}.tar.gz | tar -xz --strip-components=1

RUN yarnpkg --prod --modules-folder openvpn_monitor/static/dist install

# ----------------------------------------------------
# Stage 2: Final Python application image
# ----------------------------------------------------
FROM python:slim

# --- SET DEFAULTS HERE ---
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    OPENVPNMONITOR_DEFAULT_SITE="Global Network" \
    OPENVPNMONITOR_DEFAULT_LATITUDE=-8.7698 \
    OPENVPNMONITOR_DEFAULT_LONGITUDE=115.1691 \
    OPENVPNMONITOR_DEFAULT_DATETIMEFORMAT="%%Y-%%m-%%d %%H:%%M:%%S" \
    OPENVPNMONITOR_DEFAULT_MAPS=True \
    OPENVPNMONITOR_DEFAULT_MAPSHEIGHT=500 \
    OPENVPNMONITOR_DEFAULT_SHOWDISCONNECT=False \
    OPENVPNMONITOR_DEFAULT_GEOIP_DATA=/var/lib/GeoIP/dbip-city-lite.mmdb \
    OPENVPNMONITOR_DEFAULT_LOGO=/etc/openvpn-monitor/logo.png \
    OPENVPNMONITOR_SITES_0_NAME="Main Gateway" \
    OPENVPNMONITOR_SITES_0_HOST=localhost \
    OPENVPNMONITOR_SITES_0_PORT=5555

WORKDIR /app

RUN apt-get update && apt-get install -y wget gzip && rm -rf /var/lib/apt/lists/*

# Dynamically fetch the current month's DB-IP database
RUN mkdir -p /var/lib/GeoIP && \
    DBIP_DATE=$(date +"%Y-%m") && \
    wget -qO /var/lib/GeoIP/dbip-city-lite.mmdb.gz "https://download.db-ip.com/free/dbip-city-lite-${DBIP_DATE}.mmdb.gz" && \
    gzip -d /var/lib/GeoIP/dbip-city-lite.mmdb.gz

COPY --from=builder /src /app

# Install the app dependencies and gunicorn
RUN pip install --no-cache-dir . gunicorn

# Create the config directory and copy the logo there instead of the static folder
RUN mkdir -p /etc/openvpn-monitor
COPY assets/logo.png /etc/openvpn-monitor/logo.png

# Copy our entrypoint script
COPY entrypoint.py /usr/local/bin/entrypoint.py
RUN chmod +x /usr/local/bin/entrypoint.py

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.py"]
CMD ["gunicorn", "openvpn_monitor.app", "-b", "0.0.0.0:80"]
