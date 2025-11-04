# Use official Envoy image as base
FROM envoyproxy/envoy:v1.33-latest

# Install Python and required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /etc/envoy

# Copy Python hot-restarter script
COPY hot-restarter.py /usr/local/bin/hot-restarter.py

# Copy startup script
COPY start_envoy.sh /usr/local/bin/start_envoy.sh

# Set execute permissions
RUN chmod +x /usr/local/bin/hot-restarter.py && \
    chmod +x /usr/local/bin/start_envoy.sh

# Set environment variables
ENV RESTART_EPOCH=0
ENV SERVICE_NODE=envoy-node
ENV SERVICE_ZONE=docker
ENV ENVOY_MAX_OPEN_FILES=102400

# Expose ports used by Envoy
EXPOSE 80 9901

# Default startup command: use hot-restarter.py to start Envoy with hot-restart support
# Configuration file and parameters can be overridden in docker-compose
CMD ["python3", "/usr/local/bin/hot-restarter.py", "/usr/local/bin/start_envoy.sh"]