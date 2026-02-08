FROM grafana/alloy:latest

# Copy custom configuration
COPY config.alloy /etc/alloy/config.alloy

# Verify config file exists and has valid syntax
RUN alloy fmt --write=false /etc/alloy/config.alloy

# Default command with baked-in config path
CMD ["run", "--server.http.listen-addr=0.0.0.0:12345", "--storage.path=/var/lib/alloy", "/etc/alloy/config.alloy"]

EXPOSE 12345
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
  CMD wget --spider -q http://localhost:12345/ready || exit 1
