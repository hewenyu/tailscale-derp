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
