# tailscale-derp

基于 Docker 的 Tailscale DERP relay 和 OpenResty 反向代理一键部署方案，适用于国内 VPS，支持自动申请/续期 Let's Encrypt 证书，安全高效。

## 功能特点
- 一键部署 Tailscale DERP relay 节点
- OpenResty 反向代理，支持 WebSocket
- 自动申请/续期 Let's Encrypt SSL 证书
- 支持自签名证书防止 IP 直连
- 证书续期自动重载服务
- 适配国内 VPS 环境

## 快速开始
1. 克隆项目并进入目录
   ```bash
   git clone https://github.com/你的用户名/tailscale-derp.git
   cd tailscale-derp
   ```
2. 配置环境变量
   复制 `.env.example` 为 `.env`，并根据实际情况填写：
   ```bash
   cp .env.example .env
   ```
3. 替换 OpenResty 配置中的域名
   ```bash
   ./rename.sh your-cn-domain.com
   ```
4. 申请 SSL 证书（首次）
   ```bash
   ./iss.domain.sh your-cn-domain.com
   ```
5. 启动服务
   ```bash
   docker-compose up -d
   ```
6. 证书续期
   ```bash
   ./renew-cert.sh your-cn-domain.com
   ```

## 目录结构说明
- `derper/` DERP relay Docker 构建与启动脚本
- `openresty/` OpenResty 配置与证书目录
- `certbot/` ACME http-01 验证临时文件目录
- `acme.sh` 证书申请与续期数据目录
- `generate-self-signed-cert.sh` 生成自签名证书脚本
- `iss.domain.sh` 证书首次申请脚本
- `renew-cert.sh` 证书续期脚本
- `rename.sh` 自动替换配置域名脚本

## 证书相关
- 首次申请请运行 `iss.domain.sh`
- 续期请运行 `renew-cert.sh`
- 自签名证书用于默认 server，防止 IP 直连

## 反向代理说明
- OpenResty 监听 80/443 端口
- 反向代理到 DERP 服务，支持 WebSocket
- 证书自动挂载至容器

## 常见问题
- 证书申请失败请检查 80 端口是否被占用
- 域名需正确解析至 VPS 公网 IP
- `.env` 文件需正确配置 Tailscale 相关参数

## License
MIT License

---

如需更详细的使用说明或遇到问题，请查阅各脚本注释或提交 issue。
