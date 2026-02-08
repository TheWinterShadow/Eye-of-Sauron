FROM python:3.12-alpine

RUN apk --no-cache add wget

WORKDIR /app

COPY collector.py /app/collector.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# State persistence volume mount point
RUN mkdir -p /data
VOLUME /data

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=60s --retries=3 \
  CMD test -f /data/collector_state.json && \
      test $(($(date +%s) - $(stat -c %Y /data/collector_state.json 2>/dev/null || echo 0))) -lt 600 \
      || exit 1
