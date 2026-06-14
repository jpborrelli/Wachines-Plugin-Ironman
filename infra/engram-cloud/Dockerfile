FROM debian:bookworm-slim

ARG ENGRAM_VERSION=1.16.3
ARG TARGETARCH

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl tar \
  && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  case "${TARGETARCH:-amd64}" in \
    amd64) arch="amd64"; sha="016b7e75f788eefab20266cbfe472d86c8b08e728fafaa2379c9caab34295ae9" ;; \
    arm64) arch="arm64"; sha="6fcff5a3327855e1a560f026bcd7654e83c71273df358b7a262160af25873016" ;; \
    *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  url="https://github.com/Gentleman-Programming/engram/releases/download/v${ENGRAM_VERSION}/engram_${ENGRAM_VERSION}_linux_${arch}.tar.gz"; \
  curl -fsSL "$url" -o /tmp/engram.tar.gz; \
  echo "$sha  /tmp/engram.tar.gz" | sha256sum -c -; \
  tar -xzf /tmp/engram.tar.gz -C /usr/local/bin engram; \
  chmod +x /usr/local/bin/engram; \
  rm /tmp/engram.tar.gz

ENV ENGRAM_CLOUD_HOST=0.0.0.0
ENV ENGRAM_PORT=7437

EXPOSE 7437

CMD ["engram", "cloud", "serve"]
