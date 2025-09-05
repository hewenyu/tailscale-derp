# 证书目录

此目录用于挂载1panel管理的SSL证书。

## 使用方法

1. 在1panel中配置您的域名证书
2. 将证书文件命名为：
   - `fullchain.pem` - 完整证书链
   - `privkey.pem` - 私钥文件
3. 将此目录挂载到1panel的证书输出目录
4. 启动docker-compose服务

## 示例证书文件结构
```
certs/
├── fullchain.pem
└── privkey.pem
```

注意：此目录中的证书文件不会被提交到git仓库。