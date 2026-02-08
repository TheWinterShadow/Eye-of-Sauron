FROM ghcr.io/labbs/github-actions-exporter:latest

# This exporter is configured entirely via environment variables
# We create a wrapper script to set sensible defaults

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 9999

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --spider -q http://localhost:9999/metrics || exit 1
