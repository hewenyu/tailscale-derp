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

ENTRYPOINT ["/init.sh"] 