# ----------------------------------------------------
# Stage 1: Build JS, Python Wheels, and fetch Database
# ----------------------------------------------------
FROM python:alpine AS builder

ARG UPSTREAM_TAG=v2.0.5

# Install build dependencies
RUN apk add --no-cache wget tar gzip yarn gcc musl-dev libffi-dev python3-dev

WORKDIR /src

# Download and extract the OpenVPN Monitor source code
RUN wget -qO- https://github.com/furlongm/openvpn-monitor/archive/refs/tags/${UPSTREAM_TAG}.tar.gz | tar -xz --strip-components=1

# Build JS assets and compile Python dependencies into binary Wheels
RUN yarnpkg --prod --modules-folder openvpn_monitor/static/dist install
RUN pip wheel --no-cache-dir --wheel-dir /wheels . gunicorn

# Download and extract the current month's GeoIP Database
RUN mkdir -p /var/lib/GeoIP && \
    DBIP_DATE=$(date +"%Y-%m") && \
    wget -qO /var/lib/GeoIP/dbip-city-lite.mmdb.gz "https://download.db-ip.com/free/dbip-city-lite-${DBIP_DATE}.mmdb.gz" && \
    gzip -d /var/lib/GeoIP/dbip-city-lite.mmdb.gz

# ----------------------------------------------------
# Stage 2: Final Micro-Image
# ----------------------------------------------------
FROM python:alpine

# --- SET DEFAULTS HERE ---
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    OPENVPNMONITOR_DEFAULT_SITE="Global Network" \
    OPENVPNMONITOR_DEFAULT_LOGO=logo.png \
    OPENVPNMONITOR_DEFAULT_LATITUDE=-8.7698 \
    OPENVPNMONITOR_DEFAULT_LONGITUDE=115.1691 \
    OPENVPNMONITOR_DEFAULT_ENABLE_MAPS=True \
    OPENVPNMONITOR_DEFAULT_MAPS_HEIGHT=500 \
    OPENVPNMONITOR_DEFAULT_GEOIP_DATA=/var/lib/GeoIP/dbip-city-lite.mmdb \
    OPENVPNMONITOR_DEFAULT_DATETIME_FORMAT="%Y-%m-%d %H:%M:%S" \
    OPENVPNMONITOR_SITES_0_HOST=localhost \
    OPENVPNMONITOR_SITES_0_PORT=5555 \
    OPENVPNMONITOR_SITES_0_NAME="Main Gateway" \
    OPENVPNMONITOR_SITES_0_SHOW_DISCONNECT=False

WORKDIR /app

# 1. Copy ONLY the pre-compiled Python wheels and install them
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# 2. Copy ONLY the essential application folder (ignores tests, github assets, docs)
COPY --from=builder /src/openvpn_monitor /app/openvpn_monitor

# 3. Copy the GeoIP Database into the final image
COPY --from=builder /var/lib/GeoIP/dbip-city-lite.mmdb /var/lib/GeoIP/dbip-city-lite.mmdb

# 4. Create config directory and copy the logo
RUN mkdir -p /etc/openvpn-monitor
COPY assets/logo.png /etc/openvpn-monitor/logo.png

# 5. Copy entrypoint
COPY entrypoint.py /usr/local/bin/entrypoint.py
RUN chmod +x /usr/local/bin/entrypoint.py

# 6. Purge all Python Bytecode caches to save the final few megabytes
RUN find / -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true && \
    find / -name "*.pyc" -delete 2>/dev/null || true

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.py"]
CMD ["gunicorn", "openvpn_monitor.app", "-b", "0.0.0.0:80"]