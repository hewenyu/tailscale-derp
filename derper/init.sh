#!/usr/bin/env sh
set -e

# Ensure state dir exists
mkdir -p /var/lib/tailscale

TS_SOCK="/var/run/tailscale/tailscaled.sock"

if [ "${TAILSCALE_EMBEDDED_TAILSCALED:-true}" = "true" ]; then
  echo "启动容器内 tailscaled..."
  /usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state &> /var/lib/tailscale/tailscaled_initial.log &

  # Wait for tailscaled socket to be ready
  echo "等待 tailscaled 就绪..."
  i=0
  while [ ! -S "$TS_SOCK" ]; do
    i=$((i+1))
    if [ "$i" -gt 120 ]; then
      echo "tailscaled 启动超时，未发现 $TS_SOCK"
      exit 1
    fi
    sleep 0.5
  done

  # Bring the node up and wait for success
  echo "执行 tailscale up..."
  if ! /usr/bin/tailscale up --accept-routes=true --accept-dns=true --auth-key "${TAILSCALE_AUTH_KEY}" &> /var/lib/tailscale/tailscale_onboard.log; then
    echo "tailscale up 失败，查看 /var/lib/tailscale/tailscale_onboard.log 获取详情"
    cat /var/lib/tailscale/tailscale_onboard.log || true
    exit 1
  fi

  # Verify tailscale is running
  if ! /usr/bin/tailscale status &> /dev/null; then
    echo "tailscale 未就绪，稍后重试"
    sleep 2
  fi
else
  echo "使用宿主机 tailscaled（需要挂载 $TS_SOCK）..."
  # Wait for host tailscaled socket to appear
  i=0
  while [ ! -S "$TS_SOCK" ]; do
    i=$((i+1))
    if [ "$i" -gt 120 ]; then
      echo "未检测到宿主机 tailscaled 套接字：$TS_SOCK"
      echo "请在 docker-compose 挂载: - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro"
      exit 1
    fi
    sleep 0.5
  done
fi

# TLS mode control: auto|manual|none|letsencrypt (default: auto)
TLS_MODE=${TAILSCALE_DERP_TLS_MODE:-auto}

# Build derper command arguments
# Use single-dash flags to match Go's flag parsing
DERPER_ARGS="-hostname=$TAILSCALE_DERP_HOSTNAME -a=$TAILSCALE_DERP_ADDR -stun-port=$TAILSCALE_DERP_STUN_PORT -verify-clients=$TAILSCALE_DERP_VERIFY_CLIENTS -stun"

# If verifying clients, ensure derper uses the correct tailscaled socket
if [ "${TAILSCALE_DERP_VERIFY_CLIENTS}" = "true" ] || [ "${TAILSCALE_DERP_VERIFY_CLIENTS}" = "1" ]; then
  DERPER_ARGS="$DERPER_ARGS -socket=$TS_SOCK"
fi

# TLS configuration
case "$TLS_MODE" in
  none)
    echo "TLS_MODE=none，DERP 将以 HTTP 模式运行"
    ;;
  letsencrypt)
    echo "TLS_MODE=letsencrypt，使用内置 ACME 自动签发"
    DERPER_ARGS="$DERPER_ARGS -certmode=letsencrypt"
    ;;
  manual|auto)
    # auto: if cert files exist, go manual; otherwise HTTP
    if [ -f "$TAILSCALE_DERP_CERT_FILE" ] && [ -f "$TAILSCALE_DERP_KEY_FILE" ]; then
      echo "使用提供的证书文件: $TAILSCALE_DERP_CERT_FILE"
      DERPER_HELP=$(/derper -h 2>&1 || true)
      if echo "$DERPER_HELP" | grep -q -- "-certfile"; then
        DERPER_ARGS="$DERPER_ARGS -certmode=manual -certfile=$TAILSCALE_DERP_CERT_FILE -keyfile=$TAILSCALE_DERP_KEY_FILE"
      else
        CERT_WORKDIR="/app/certs-work"
        mkdir -p "$CERT_WORKDIR"
        # Newer derper expects hostname-specific filenames in certdir
        ln -sf "$TAILSCALE_DERP_CERT_FILE" "$CERT_WORKDIR/${TAILSCALE_DERP_HOSTNAME}.crt"
        ln -sf "$TAILSCALE_DERP_KEY_FILE" "$CERT_WORKDIR/${TAILSCALE_DERP_HOSTNAME}.key"
        DERPER_ARGS="$DERPER_ARGS -certmode=manual -certdir=$CERT_WORKDIR"
      fi
    else
      if [ "$TLS_MODE" = "manual" ]; then
        echo "错误: TLS_MODE=manual，但未找到证书文件 ($TAILSCALE_DERP_CERT_FILE / $TAILSCALE_DERP_KEY_FILE)"
        exit 1
      fi
      echo "未发现证书文件，DERP 将以 HTTP 模式运行"
    fi
    ;;
  *)
    echo "未知 TLS 模式: $TLS_MODE"
    exit 1
    ;;
esac

# Start Tailscale derp server
exec /derper $DERPER_ARGS
