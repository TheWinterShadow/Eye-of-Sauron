FROM mvisonneau/gitlab-ci-pipelines-exporter:latest

# Copy custom configuration
COPY config.yml /etc/config.yml

# Verify config file exists
RUN test -f /etc/config.yml || (echo "config.yml not found" && exit 1)

# Default command with baked-in config path
CMD ["run", "--config", "/etc/config.yml"]

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget --spider -q http://localhost:8080/metrics || exit 1
