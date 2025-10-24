@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ================================
echo   Node Staking Admin Backend
echo   一键 Docker 部署脚本 (Windows)
echo ================================
echo.

REM 检查 Docker 是否安装
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未安装，请先安装 Docker Desktop
    pause
    exit /b 1
)

echo ✅ Docker 环境检查通过

REM 创建项目目录
if not exist "node-staking-admin-backend" mkdir node-staking-admin-backend
cd node-staking-admin-backend

echo 📁 创建项目文件...

REM 创建 package.json
(
echo {
echo   "name": "node-staking-admin-backend",
echo   "version": "1.0.0",
echo   "type": "module",
echo   "main": "server.js",
echo   "dependencies": {
echo     "express": "^4.18.2",
echo     "ethers": "^6.8.1",
echo     "dotenv": "^16.3.1",
echo     "helmet": "^7.1.0",
echo     "cors": "^2.8.5",
echo     "morgan": "^1.10.0",
echo     "winston": "^3.11.0"
echo   }
echo }
) > package.json

REM 创建 Dockerfile
(
echo FROM node:20-slim
echo WORKDIR /app
echo COPY package*.json ./
echo RUN npm ci --only=production
echo COPY . .
echo RUN mkdir -p logs
echo EXPOSE 3000
echo CMD ["node", "server.js"]
) > Dockerfile

REM 创建环境变量文件
(
echo NODE_ENV=production
echo PORT=3000
echo HOST=0.0.0.0
echo API_KEY=your_secure_api_key_here_change_this_in_production
echo RPC_URLS=https://bsc-testnet.publicnode.com,https://data-seed-prebsc-1-s1.binance.org:8545
echo CONTRACT_ADDRESS=0x1234567890123456789012345678901234567890
echo ADMIN_PRIVATE_KEY=your_admin_private_key_here_never_commit_this_to_git
echo LOG_LEVEL=info
echo CORS_ORIGIN=*
) > .env

REM 创建 ABI 目录和文件
if not exist "abi" mkdir abi
(
echo {
echo   "abi": [
echo     {
echo       "inputs": [],
echo       "name": "governor",
echo       "outputs": [{"internalType": "address", "name": "", "type": "address"}],
echo       "stateMutability": "view",
echo       "type": "function"
echo     },
echo     {
echo       "inputs": [],
echo       "name": "activeNodes",
echo       "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
echo       "stateMutability": "view",
echo       "type": "function"
echo     },
echo     {
echo       "inputs": [],
echo       "name": "rewardPerNode",
echo       "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
echo       "stateMutability": "view",
echo       "type": "function"
echo     },
echo     {
echo       "inputs": [],
echo       "name": "tbv",
echo       "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
echo       "stateMutability": "view",
echo       "type": "function"
echo     }
echo   ],
echo   "description": "请将您的实际合约 ABI 替换此文件内容"
echo }
) > abi\NodeStakingUpgradeable.json

REM 创建简化的服务器文件
(
echo import express from 'express';
echo import cors from 'cors';
echo import helmet from 'helmet';
echo import morgan from 'morgan';
echo import dotenv from 'dotenv';
echo.
echo dotenv.config^(^);
echo.
echo const app = express^(^);
echo.
echo // 中间件
echo app.use^(helmet^(^)^);
echo app.use^(cors^(^)^);
echo app.use^(morgan^('combined'^)^);
echo app.use^(express.json^(^)^);
echo.
echo // 健康检查
echo app.get^('/health', ^(req, res^) =^> {
echo   res.json^({
echo     status: 'healthy',
echo     timestamp: new Date^(^).toISOString^(^),
echo     uptime: process.uptime^(^)
echo   }^);
echo }^);
echo.
echo // 根路径
echo app.get^('/', ^(req, res^) =^> {
echo   res.json^({
echo     message: 'Node Staking Admin Backend',
echo     version: '1.0.0',
echo     status: 'running',
echo     endpoints: {
echo       health: '/health',
echo       admin: '/api/admin/*'
echo     }
echo   }^);
echo }^);
echo.
echo // 简单的管理员路由
echo app.post^('/api/admin/status', ^(req, res^) =^> {
echo   const apiKey = req.headers['x-api-key'] ^|^| req.query.api_key;
echo   
echo   if ^(!apiKey ^|^| apiKey !== process.env.API_KEY^) {
echo     return res.status^(401^).json^({
echo       error: 'Unauthorized',
echo       message: 'API key is required'
echo     }^);
echo   }
echo   
echo   res.json^({
echo     success: true,
echo     data: {
echo       governor: '0x0000000000000000000000000000000000000000',
echo       activeNodes: '0',
echo       rewardPerNode: '0',
echo       tbv: '0'
echo     },
echo     timestamp: new Date^(^).toISOString^(^)
echo   }^);
echo }^);
echo.
echo // 404 处理
echo app.use^('*', ^(req, res^) =^> {
echo   res.status^(404^).json^({
echo     error: 'Not Found',
echo     message: `Route ${req.originalUrl} not found`
echo   }^);
echo }^);
echo.
echo // 启动服务器
echo const port = process.env.PORT ^|^| 3000;
echo const host = process.env.HOST ^|^| '0.0.0.0';
echo.
echo app.listen^(port, host, ^(^) =^> {
echo   console.log^(`🚀 Server running on ${host}:${port}`^);
echo   console.log^(`📊 Environment: ${process.env.NODE_ENV}`^);
echo   console.log^(`🔗 Health check: http://${host}:${port}/health`^);
echo }^);
) > server.js

REM 创建日志目录
if not exist "logs" mkdir logs

echo 📦 构建 Docker 镜像...
docker build -t node-staking-admin .

if %errorlevel% neq 0 (
    echo ❌ Docker 镜像构建失败
    pause
    exit /b 1
)

echo 🚀 启动 Docker 容器...

REM 停止并删除已存在的容器
docker stop node-staking-admin 2>nul
docker rm node-staking-admin 2>nul

REM 启动新容器
docker run -d ^
  --name node-staking-admin ^
  -p 3000:3000 ^
  -v "%cd%\abi:/app/abi:ro" ^
  -v "%cd%\logs:/app/logs" ^
  --env-file .env ^
  node-staking-admin

if %errorlevel% neq 0 (
    echo ❌ Docker 容器启动失败
    pause
    exit /b 1
)

echo.
echo 🎉 部署完成！
echo.
echo 📊 服务信息:
echo   服务地址: http://localhost:3000
echo   健康检查: http://localhost:3000/health
echo   API 状态: http://localhost:3000/api/admin/status
echo.
echo 🔧 管理命令:
echo   查看日志: docker logs -f node-staking-admin
echo   停止服务: docker stop node-staking-admin
echo   重启服务: docker restart node-staking-admin
echo.
echo ⚠️  重要提醒:
echo   1. 请编辑 .env 文件，设置正确的 API_KEY 和 CONTRACT_ADDRESS
echo   2. 请将实际的合约 ABI 放入 abi\NodeStakingUpgradeable.json
echo   3. 生产环境请设置强密码和访问控制
echo.
echo ✅ 快速部署完成！
echo.
pause
