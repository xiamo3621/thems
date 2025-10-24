#!/bin/bash

# Node Staking Admin Backend - 快速一键部署脚本
# 使用方法: chmod +x quick-deploy.sh && ./quick-deploy.sh

set -e

echo "🚀 Node Staking Admin Backend - 快速部署"
echo "========================================"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

echo "✅ Docker 环境检查通过"

# 创建项目目录
mkdir -p node-staking-admin-backend
cd node-staking-admin-backend

# 创建 package.json
cat > package.json << 'EOF'
{
  "name": "node-staking-admin-backend",
  "version": "1.0.0",
  "type": "module",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "ethers": "^6.8.1",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "morgan": "^1.10.0",
    "winston": "^3.11.0"
  }
}
EOF

# 创建 Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN mkdir -p logs
EXPOSE 3000
CMD ["node", "server.js"]
EOF

# 创建环境变量文件
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
API_KEY=your_secure_api_key_here_change_this_in_production
RPC_URLS=https://bsc-testnet.publicnode.com,https://data-seed-prebsc-1-s1.binance.org:8545
CONTRACT_ADDRESS=0x1234567890123456789012345678901234567890
ADMIN_PRIVATE_KEY=your_admin_private_key_here_never_commit_this_to_git
LOG_LEVEL=info
CORS_ORIGIN=*
EOF

# 创建 ABI 目录和文件
mkdir -p abi
cat > abi/NodeStakingUpgradeable.json << 'EOF'
{
  "abi": [
    {
      "inputs": [],
      "name": "governor",
      "outputs": [{"internalType": "address", "name": "", "type": "address"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "activeNodes",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "rewardPerNode",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "tbv",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    }
  ],
  "description": "请将您的实际合约 ABI 替换此文件内容"
}
EOF

# 创建简化的服务器文件
cat > server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

dotenv.config();

const app = express();

// 中间件
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// 根路径
app.get('/', (req, res) => {
  res.json({
    message: 'Node Staking Admin Backend',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: '/health',
      admin: '/api/admin/*'
    }
  });
});

// 简单的管理员路由
app.post('/api/admin/status', (req, res) => {
  const apiKey = req.headers['x-api-key'] || req.query.api_key;
  
  if (!apiKey || apiKey !== process.env.API_KEY) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'API key is required'
    });
  }
  
  res.json({
    success: true,
    data: {
      governor: '0x0000000000000000000000000000000000000000',
      activeNodes: '0',
      rewardPerNode: '0',
      tbv: '0'
    },
    timestamp: new Date().toISOString()
  });
});

// 404 处理
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`
  });
});

// 启动服务器
const port = process.env.PORT || 3000;
const host = process.env.HOST || '0.0.0.0';

app.listen(port, host, () => {
  console.log(`🚀 Server running on ${host}:${port}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔗 Health check: http://${host}:${port}/health`);
});
EOF

# 创建日志目录
mkdir -p logs

echo "📦 构建 Docker 镜像..."
docker build -t node-staking-admin .

echo "🚀 启动 Docker 容器..."
docker stop node-staking-admin 2>/dev/null || true
docker rm node-staking-admin 2>/dev/null || true

docker run -d \
  --name node-staking-admin \
  -p 3000:3000 \
  -v $(pwd)/abi:/app/abi:ro \
  -v $(pwd)/logs:/app/logs \
  --env-file .env \
  node-staking-admin

echo ""
echo "🎉 部署完成！"
echo ""
echo "📊 服务信息:"
echo "  服务地址: http://localhost:3000"
echo "  健康检查: http://localhost:3000/health"
echo "  API 状态: http://localhost:3000/api/admin/status"
echo ""
echo "🔧 管理命令:"
echo "  查看日志: docker logs -f node-staking-admin"
echo "  停止服务: docker stop node-staking-admin"
echo "  重启服务: docker restart node-staking-admin"
echo ""
echo "⚠️  重要提醒:"
echo "  1. 请编辑 .env 文件，设置正确的 API_KEY 和 CONTRACT_ADDRESS"
echo "  2. 请将实际的合约 ABI 放入 abi/NodeStakingUpgradeable.json"
echo "  3. 生产环境请设置强密码和访问控制"
echo ""
echo "✅ 快速部署完成！"
