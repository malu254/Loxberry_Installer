FROM debian:bookworm

# Non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DOCKER_INSTALL=1

# Install basic dependencies first
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        lsb-release \
        jq \
        gnupg \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy install script
COPY install_bookworm.sh /install.sh
RUN chmod +x /install.sh

# Run the LoxBerry installer in Docker mode
RUN /install.sh

# Copy Docker entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose ports
# 80:   HTTP web interface
# 443:  HTTPS web interface
# 1883: MQTT (unencrypted)
# 8883: MQTT (TLS)
# 22:   SSH
EXPOSE 80 443 1883 8883 22

ENTRYPOINT ["/docker-entrypoint.sh"]
