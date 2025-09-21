# Use kas container tag as build argument (allows user customization)
ARG KAS_TAG=latest
FROM ghcr.io/siemens/kas/kas:${KAS_TAG}

# Switch to root to install packages
USER root

# Install additional tools commonly needed by Yocto layers
# - git: Version control operations
# - openssh-client: SSH access for private repositories
# - ca-certificates: SSL/TLS certificate validation
# - xz-utils: Compression/decompression
# - file: File type detection
# - locales: Locale support for builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    ca-certificates \
    xz-utils \
    file \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Generate common locales to avoid build warnings
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# Set default locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Copy our entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Switch back to builder user (kas default)
USER builder

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
