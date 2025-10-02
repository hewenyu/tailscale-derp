# syntax=docker/dockerfile:1

FROM golang:1.25-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
RUN git clone https://github.com/tailscale/tailscale.git .

RUN go build -o /derper ./cmd/derper

FROM alpine:latest

# Install tailscale directly via apk (avoid install.sh which expects openrc)
RUN apk add --no-cache ca-certificates tailscale

WORKDIR /app
COPY --from=builder /derper /derper

COPY init.sh /init.sh

RUN chmod +x /init.sh
ENV TAILSCALE_DERP_ADDR=":1443"
ENV TAILSCALE_DERP_HOSTNAME="derp.example.com"
ENV TAILSCALE_DERP_STUN_PORT="3478"
ENV TAILSCALE_DERP_VERIFY_CLIENTS="true"
ENV TAILSCALE_DERP_CERT_FILE="/certs/fullchain.pem"
ENV TAILSCALE_DERP_KEY_FILE="/certs/privkey.pem"
ENV TAILSCALE_EMBEDDED_TAILSCALED="true"

EXPOSE 1443 80 3478/udp

ENTRYPOINT ["/init.sh"]
