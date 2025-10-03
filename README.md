# tailscale-derp

基于 Docker 的 Tailscale DERP relay 一键部署方案，专为与1panel配合使用而设计。

## 功能特点
- 一键部署 Tailscale DERP relay 节点
- 支持1panel证书管理集成
- 直接HTTPS支持，无需反向代理
- 自动检测证书文件，支持HTTP和HTTPS模式
- 适配国内 VPS 环境

## 快速开始

### 1. 克隆项目并进入目录
```bash
git clone https://github.com/你的用户名/tailscale-derp.git
cd tailscale-derp
```

### 2. 配置环境变量
复制 `.env.example` 为 `.env`，并根据实际情况填写：
```bash
cp .env.example .env
```

主要配置项：
- `TAILSCALE_DERP_HOSTNAME`: 您的域名
- `TAILSCALE_AUTH_KEY`: Tailscale认证密钥
- `TAILSCALE_DERP_CERT_FILE`: 证书文件路径（容器内）
- `TAILSCALE_DERP_KEY_FILE`: 私钥文件路径（容器内）

### 3. 证书配置（使用1panel）
1. 在1panel中为您的域名申请/配置SSL证书
2. 将证书文件复制到 `./certs/` 目录：
   - `fullchain.pem` - 完整证书链
   - `privkey.pem` - 私钥文件

### 4. 启动服务
```bash
docker-compose up -d
```

## 目录结构说明
- `derper/` - DERP relay Docker 构建与启动脚本  
- `certs/` - 1panel证书文件目录（挂载点）

## 证书管理
本项目设计为与1panel配合使用：
- 证书申请和续期由1panel自动管理
- 将1panel的证书输出目录挂载到 `./certs/`
- 服务会自动检测证书文件并启用HTTPS

## 网络端口
- `80` - HTTP（可选，用于重定向到HTTPS）
- `443` - HTTPS DERP服务
- `3478/udp` - STUN端口

## 常见问题
- 如果没有证书文件，服务将运行在HTTP模式
- 确保域名正确解析至 VPS 公网 IP
- `.env` 文件需正确配置 Tailscale 相关参数

## 运行模式

默认采用“内置 tailscaled”模式：容器内启动 tailscaled 并执行 `tailscale up`，需要 `TAILSCALE_AUTH_KEY`、`cap_add` 和 `/dev/net/tun`。

如果你的宿主机已运行 tailscaled，也可以复用宿主机 tailscaled：

1) 在 `.env` 设置：
```
TAILSCALE_EMBEDDED_TAILSCALED=false
```

2) 在 `docker-compose.yml` 挂载宿主机 socket：
```yaml
services:
  derp:
    volumes:
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro
```

3) 可移除以下内容（宿主机模式不需要）：
- `cap_add: [NET_ADMIN, NET_RAW]`
- `devices: - /dev/net/tun:/dev/net/tun`
- `/lib/modules` 挂载
- `.env` 中的 `TAILSCALE_AUTH_KEY`

## 反向代理与回源 SNI

如果你使用 1Panel/OpenResty 或其他反向代理把公网 443 流量转发到 DERP，有两种常见方式：

- TLS 直通（四层透传，推荐）：
  - 使用 Nginx/OpenResty `stream` 转发 443 到容器内 `:1443`，开启 `ssl_preread` 以透传 SNI。
  - 客户端的 SNI 必须是与你证书一致的域名，即 `.env` 中的 `TAILSCALE_DERP_HOSTNAME`。

- TLS 终止 + 回源（七层反向代理）：
  - 若后端 DERP 仍使用 HTTPS（默认自动/手动证书），必须在回源时携带 SNI；否则会出现证书/SNI 不匹配导致握手失败。
  - Nginx 示例（HTTPS 回源）：
    ```nginx
    location / {
      proxy_pass https://127.0.0.1:1443;
      proxy_set_header Host derp.example.com;      # 与 TAILSCALE_DERP_HOSTNAME 一致
      proxy_ssl_server_name on;                    # 开启回源 SNI
      proxy_ssl_name derp.example.com;             # 设置回源 SNI 名称
      # 可选：校验后端证书
      # proxy_ssl_verify on;
      # proxy_ssl_trusted_certificate /path/to/ca.pem;
    }
    ```

  - 如果你希望由反向代理终止 TLS，后端仅走明文 HTTP，可将 DERP 置为 HTTP 模式：在 `.env` 设置 `TAILSCALE_DERP_TLS_MODE=none`，并把回源地址改为 `http://127.0.0.1:1443`。此时无需回源 SNI。

提示：本镜像支持通过环境变量 `TAILSCALE_DERP_TLS_MODE` 控制 TLS 行为：`auto`（默认，检测证书自动启用）、`manual`（必须提供证书文件）、`letsencrypt`（内置 ACME）、`none`（纯 HTTP）。当选择 `auto/manual/letsencrypt` 时，使用反向代理回源 HTTPS 需正确设置回源 SNI（见上）。

## 与原版区别
此版本移除了：
- OpenResty反向代理配置
- 自动证书申请/续期脚本
- 复杂的证书管理逻辑

简化为：
- 纯Docker容器部署
- 1panel证书集成
- 直接HTTPS支持

## License
MIT License

---

如需更详细的使用说明或遇到问题，请提交 issue。
