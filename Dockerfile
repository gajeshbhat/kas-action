# Use kas container tag as build argument (allows user customization)
ARG KAS_TAG=latest
FROM ghcr.io/siemens/kas/kas:${KAS_TAG}

# Switch to root for configuration
# hadolint ignore=DL3002
USER root

# Set locale environment variables (base image already has en_US.UTF-8 configured)
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Copy our entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Run as root to handle GitHub Actions workspace permissions
# The entrypoint will drop privileges to builder user for kas execution

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
