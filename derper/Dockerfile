# syntax=docker/dockerfile:1

FROM golang:1.24-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
RUN git clone https://github.com/tailscale/tailscale.git .

RUN go build -o /derper ./cmd/derper

FROM alpine:latest

RUN apk add --no-cache tailscale

WORKDIR /app
COPY --from=builder /derper /derper

COPY init.sh /init.sh

RUN chmod +x /init.sh

ENV TAILSCALE_AUTH_KEY="TTTT"
ENV TAILSCALE_DERP_ADDR=":1443"
ENV TAILSCALE_DERP_HOSTNAME="derp.example.com"
ENV TAILSCALE_DERP_STUN_PORT="3478"
ENV TAILSCALE_DERP_VERIFY_CLIENTS="true"

EXPOSE 1443

ENTRYPOINT ["/init.sh"]