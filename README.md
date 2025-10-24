 🚀 Node Staking Admin Backend - 一键部署指南

## 📋 部署方式选择

### 方式一：Linux/macOS 一键部署
```bash
# 下载并运行部署脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/node-staking-admin-backend/main/deploy.sh | bash

# 或者手动下载后运行
chmod +x deploy.sh
./deploy.sh
```

### 方式二：快速部署（简化版）
```bash
# 运行快速部署脚本
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### 方式三：Windows 一键部署
```cmd
# 双击运行或在命令行执行
deploy.bat
```

## 🐳 Docker 一键部署命令

### 完整版部署（推荐）
```bash
# 1. 克隆或下载项目
git clone <repository-url>
cd node-staking-admin-backend

# 2. 运行一键部署脚本
chmod +x deploy.sh
./deploy.sh
```

### 简化版部署
```bash
# 1. 下载快速部署脚本
wget https://raw.githubusercontent.com/your-repo/node-staking-admin-backend/main/quick-deploy.sh

# 2. 运行部署
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Windows 部署
```cmd
# 1. 下载 deploy.bat 文件
# 2. 双击运行或在命令行执行
deploy.bat
```

## 🔧 部署后配置

### 1. 编辑环境变量
```bash
# 编辑 .env 文件
nano .env

# 或使用 vim
vim .env
```

**必须修改的配置项：**
```bash
# API 安全密钥（必须修改）
API_KEY=your_secure_api_key_here_change_this_in_production

# 合约地址（必须修改为实际地址）
CONTRACT_ADDRESS=0x你的实际合约地址

# RPC 节点（可选，默认使用 BSC 测试网）
RPC_URLS=https://bsc-testnet.publicnode.com,https://data-seed-prebsc-1-s1.binance.org:8545

# 管理员私钥（用于写操作，可选）
ADMIN_PRIVATE_KEY=your_admin_private_key_here_never_commit_this_to_git
```

### 2. 放置合约 ABI
```bash
# 将您的实际合约 ABI 文件放入 abi 目录
cp /path/to/your/NodeStakingUpgradeable.json abi/NodeStakingUpgradeable.json
```

### 3. 重启服务
```bash
# 重启 Docker 容器
docker restart node-staking-admin

# 或使用 docker-compose
docker-compose restart
```

## 🧪 测试部署

### 1. 健康检查
```bash
# 检查服务状态
curl http://localhost:3000/health

# 预期返回：
# {
#   "status": "healthy",
#   "timestamp": "2024-01-01T00:00:00.000Z",
#   "uptime": 123.456
# }
```

### 2. API 测试
```bash
# 测试管理员接口（需要 API 密钥）
curl -H "x-api-key: your_api_key" \
  http://localhost:3000/api/admin/status

# 预期返回：
# {
#   "success": true,
#   "data": {
#     "governor": "0x...",
#     "activeNodes": "0",
#     "rewardPerNode": "0",
#     "tbv": "0"
#   }
# }
```

## 📊 服务管理

### 查看服务状态
```bash
# 查看容器状态
docker ps | grep node-staking-admin

# 查看服务日志
docker logs -f node-staking-admin

# 查看实时日志
docker logs --tail 100 -f node-staking-admin
```

### 服务控制
```bash
# 停止服务
docker stop node-staking-admin

# 启动服务
docker start node-staking-admin

# 重启服务
docker restart node-staking-admin

# 删除服务
docker rm -f node-staking-admin
```

### 更新部署
```bash
# 停止旧服务
docker stop node-staking-admin
docker rm node-staking-admin

# 重新构建和启动
docker build -t node-staking-admin .
docker run -d --name node-staking-admin -p 3000:3000 \
  -v $(pwd)/abi:/app/abi:ro \
  -v $(pwd)/logs:/app/logs \
  --env-file .env \
  node-staking-admin
```

## 🔍 故障排除

### 常见问题

1. **端口被占用**
```bash
# 查找占用端口的进程
lsof -i :3000
# 杀死进程
kill -9 <PID>
```

2. **Docker 权限问题**
```bash
# 添加用户到 docker 组
sudo usermod -aG docker $USER
# 重新登录或重启
```

3. **容器启动失败**
```bash
# 查看详细错误信息
docker logs node-staking-admin

# 检查环境变量
docker exec node-staking-admin env
```

4. **API 认证失败**
```bash
# 检查 API 密钥配置
grep API_KEY .env

# 测试 API 密钥
curl -H "x-api-key: your_api_key" \
  http://localhost:3000/api/admin/status
```

## 🛡️ 安全配置

### 生产环境安全设置

1. **修改默认密码**
```bash
# 生成强随机 API 密钥
openssl rand -hex 32

# 更新 .env 文件
API_KEY=your_generated_secure_key_here
```

2. **配置防火墙**
```bash
# 只允许必要端口
sudo ufw allow 3000
sudo ufw allow 22
sudo ufw enable
```

3. **使用 HTTPS**
```bash
# 配置 Nginx 反向代理
# 或使用 Let's Encrypt 证书
```

## 📈 监控和维护

### 日志监控
```bash
# 实时监控日志
docker logs -f node-staking-admin

# 查看错误日志
docker logs node-staking-admin 2>&1 | grep ERROR

# 查看访问日志
docker logs node-staking-admin 2>&1 | grep "HTTP"
```

### 性能监控
```bash
# 查看容器资源使用
docker stats node-staking-admin

# 查看系统资源
htop
df -h
```

## 🎯 部署检查清单

- [ ] Docker 环境准备完成
- [ ] 项目文件下载完成
- [ ] 环境变量配置正确
- [ ] 合约 ABI 文件放置
- [ ] API 密钥设置
- [ ] 合约地址配置
- [ ] 服务启动成功
- [ ] 健康检查通过
- [ ] API 接口测试通过
- [ ] 日志记录正常

## 📞 技术支持

如果遇到问题，请检查：

1. **Docker 版本**：确保 Docker 版本 >= 20.0
2. **系统资源**：确保有足够的内存和磁盘空间
3. **网络连接**：确保可以访问 RPC 节点
4. **配置文件**：确保 .env 文件配置正确
5. **日志信息**：查看详细的错误日志

## 🎉 部署成功

部署完成后，您将获得：

- ✅ 完整的 Node.js 管理后台
- ✅ Docker 容器化部署
- ✅ 自动健康检查
- ✅ 完整的日志记录
- ✅ 安全的 API 认证
- ✅ 多 RPC 故障转移
- ✅ 生产环境就绪

**服务地址：** http://localhost:3000  
**健康检查：** http://localhost:3000/health  
**API 文档：** http://localhost:3000/api/admin/*
