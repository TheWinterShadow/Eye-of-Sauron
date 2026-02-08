# Stage 1: Build from source for true multi-arch support
# (upstream ghcr.io/labbs/github-actions-exporter is amd64-only)
FROM golang:1.18-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src
RUN git clone https://github.com/Labbs/github-actions-exporter.git .

ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    go build -a -installsuffix cgo -o /out/github-actions-exporter

# Stage 2: Minimal runtime image
FROM alpine:latest

RUN apk --no-cache add ca-certificates wget

COPY --from=builder /out/github-actions-exporter /app/github-actions-exporter
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 9999

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --spider -q http://localhost:9999/metrics || exit 1
