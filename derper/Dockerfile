# syntax=docker/dockerfile:1

FROM golang:1.23.3-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

RUN go install tailscale.com/cmd/derper@latest

FROM alpine:latest

RUN apk add --no-cache tailscale

COPY --from=builder /go/bin/derper /usr/local/bin/derper

COPY init.sh /init.sh

RUN chmod +x /init.sh

ENV TAILSCALE_AUTH_KEY="TTTT"
ENV TAILSCALE_DERP_ADDR=":443"
ENV TAILSCALE_DERP_HOSTNAME="derp.example.com"
ENV TAILSCALE_DERP_STUN_PORT="3478"
ENV TAILSCALE_DERP_VERIFY_CLIENTS="true"
EXPOSE 443

ENTRYPOINT ["/init.sh"] 