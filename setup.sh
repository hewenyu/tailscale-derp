#!/bin/bash
# 示例部署脚本 - Example deployment script

set -e

echo "开始配置 Tailscale DERP 服务..."

# 检查必需的环境
if [ ! -f ".env" ]; then
    echo "创建 .env 配置文件..."
    cp .env.example .env
    echo "请编辑 .env 文件，设置您的域名和认证密钥"
    echo "主要配置项："
    echo "- TAILSCALE_DERP_HOSTNAME: 您的域名"
    echo "- TAILSCALE_AUTH_KEY: Tailscale认证密钥"
    exit 1
fi

# 创建必需的目录
echo "创建配置目录..."
mkdir -p derp/config
mkdir -p certs

# 检查证书文件
if [ ! -f "certs/fullchain.pem" ] || [ ! -f "certs/privkey.pem" ]; then
    echo "警告: 未找到证书文件"
    echo "请将您的证书文件放置在以下位置："
    echo "- certs/fullchain.pem"
    echo "- certs/privkey.pem"
    echo ""
    echo "或者配置1panel证书挂载到 certs/ 目录"
    echo ""
    echo "没有证书的情况下，服务将运行在HTTP模式"
fi

# 验证配置
echo "验证 docker-compose 配置..."
if ! docker compose config > /dev/null; then
    echo "错误: docker-compose 配置无效"
    exit 1
fi

echo "配置验证通过！"
echo ""
echo "现在可以启动服务："
echo "  docker compose up -d"
echo ""
echo "查看日志："
echo "  docker compose logs -f derp"
echo ""
echo "停止服务："
echo "  docker compose down"