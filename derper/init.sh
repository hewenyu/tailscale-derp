#!/usr/bin/env sh
set -e

# Ensure state dir exists
mkdir -p /var/lib/tailscale

# Start tailscaled and connect to tailnet
/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state &> /var/lib/tailscale/tailscaled_initial.log &

# Start the DERP server with the specified parameters
/usr/bin/tailscale up --accept-routes=true --accept-dns=true --auth-key "${TAILSCALE_AUTH_KEY}" &> /var/lib/tailscale/tailscale_onboard.log &

# Build derper command arguments
DERPER_ARGS="--hostname=$TAILSCALE_DERP_HOSTNAME --a=$TAILSCALE_DERP_ADDR --stun-port=$TAILSCALE_DERP_STUN_PORT --verify-clients=$TAILSCALE_DERP_VERIFY_CLIENTS --stun"

# Add certificate configuration if files exist
if [ -f "$TAILSCALE_DERP_CERT_FILE" ] && [ -f "$TAILSCALE_DERP_KEY_FILE" ]; then
    echo "使用提供的证书文件: $TAILSCALE_DERP_CERT_FILE"
    DERPER_ARGS="$DERPER_ARGS --certfile=$TAILSCALE_DERP_CERT_FILE --keyfile=$TAILSCALE_DERP_KEY_FILE"
else
    echo "警告: 未找到证书文件，DERP服务器将运行在HTTP模式"
    echo "请确保1panel已正确配置证书并挂载到 /certs 目录"
fi

# Start Tailscale derp server
exec /derper $DERPER_ARGS
