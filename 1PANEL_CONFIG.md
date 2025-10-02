# 1Panel集成配置说明

## 1panel证书配置

### 1. 在1panel中申请证书
1. 登录1panel管理界面
2. 进入"网站" -> "证书"
3. 为您的域名申请Let's Encrypt证书或上传自有证书

### 2. 证书文件路径配置
1panel通常将证书保存在以下位置：
```
/opt/1panel/data/apps/openresty/ssl/
```

### 3. Docker-compose挂载配置
修改docker-compose.yml中的证书挂载路径：

```yaml
services:
  derp:
    volumes:
      # 其他挂载...
      - /opt/1panel/data/apps/openresty/ssl/your-domain:/certs:ro
```

### 4. 1panel反向代理配置（可选）
如果您希望通过1panel的OpenResty进行反向代理而不是直接暴露DERP服务：

1. 在1panel中创建网站
2. 配置反向代理到 `http://localhost:1443`
3. 修改docker-compose.yml，移除端口80和443的映射：

```yaml
services:
  derp:
    ports:
      - "3478:3478/udp"  # 只保留STUN端口
      # 移除: - "80:80"
      # 移除: - "443:1443"
```

### 5. 环境变量配置
确保.env文件中的域名与1panel中配置的域名一致：
```
TAILSCALE_DERP_HOSTNAME=your-domain.com
```

### 6. 复用宿主机 tailscaled（可选）
如果宿主机已安装并运行 Tailscale，DERP 容器可以直接复用宿主机的 tailscaled：

1) 在 `.env` 设置：
```
TAILSCALE_EMBEDDED_TAILSCALED=false
```

2) 在 docker-compose 挂载 tailscaled 套接字：
```yaml
services:
  derp:
    volumes:
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock:ro
```

3) 可移除以下内容：
- `cap_add: [NET_ADMIN, NET_RAW]`
- `devices: - /dev/net/tun:/dev/net/tun`
- `/lib/modules` 挂载
- `.env` 中的 `TAILSCALE_AUTH_KEY`

## 故障排除

### 证书文件权限问题
如果遇到证书文件权限问题，可以调整证书文件权限：
```bash
sudo chmod 644 /path/to/fullchain.pem
sudo chmod 600 /path/to/privkey.pem
```

### 验证证书是否正确挂载
```bash
docker exec derp ls -la /certs/
```

### 查看DERP服务日志
```bash
docker logs derp
```
