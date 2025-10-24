#!/bin/bash

# Node Staking Admin Backend - 一键 Docker 部署脚本
# 使用方法: chmod +x deploy.sh && ./deploy.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Node Staking Admin Backend${NC}"
    echo -e "${BLUE} 一键 Docker 部署脚本${NC}"
    echo -e "${BLUE}================================${NC}"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_warning "docker-compose 未安装，将使用 docker compose"
    fi
    
    print_message "Docker 环境检查通过"
}

# 创建必要的目录
create_directories() {
    print_message "创建必要的目录..."
    
    mkdir -p abi
    mkdir -p logs
    mkdir -p src/middleware
    mkdir -p src/services
    mkdir -p src/routes
    mkdir -p src/utils
    
    print_message "目录创建完成"
}

# 创建 package.json
create_package_json() {
    print_message "创建 package.json..."
    
    cat > package.json << 'EOF'
{
  "name": "node-staking-admin-backend",
  "version": "1.0.0",
  "description": "Node.js 管理后台项目，用于管理并操作已部署的 NodeStakingUpgradeable 合约",
  "type": "module",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js",
    "docker:build": "docker build -t node-staking-admin .",
    "docker:run": "docker run -d --name node-staking-admin -p 3000:3000 node-staking-admin",
    "docker:compose": "docker-compose up -d",
    "docker:compose:down": "docker-compose down"
  },
  "keywords": [
    "nodejs",
    "ethereum",
    "staking",
    "admin",
    "bsc",
    "contract"
  ],
  "author": "Node Staking Admin",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "ethers": "^6.8.1",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "morgan": "^1.10.0",
    "winston": "^3.11.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
    
    print_message "package.json 创建完成"
}

# 创建 Dockerfile
create_dockerfile() {
    print_message "创建 Dockerfile..."
    
    cat > Dockerfile << 'EOF'
# 使用 Node.js 20 官方镜像
FROM node:20-slim

# 设置工作目录
WORKDIR /app

# 创建非 root 用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 复制 package 文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production && npm cache clean --force

# 复制应用代码
COPY . .

# 创建日志目录
RUN mkdir -p logs && chown -R appuser:appuser /app

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# 启动应用
CMD ["node", "server.js"]
EOF
    
    print_message "Dockerfile 创建完成"
}

# 创建 docker-compose.yml
create_docker_compose() {
    print_message "创建 docker-compose.yml..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  admin:
    build: .
    container_name: node-staking-admin
    ports:
      - "3000:3000"
    volumes:
      - ./abi:/app/abi:ro
      - ./logs:/app/logs
    environment:
      - NODE_ENV=production
    env_file:
      - .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - admin-network

networks:
  admin-network:
    driver: bridge
EOF
    
    print_message "docker-compose.yml 创建完成"
}

# 创建环境变量文件
create_env_file() {
    print_message "创建环境变量文件..."
    
    cat > .env << 'EOF'
# 服务器配置
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# API 安全配置
API_KEY=your_secure_api_key_here_change_this_in_production

# 区块链网络配置
RPC_URLS=https://bsc-testnet.publicnode.com,https://data-seed-prebsc-1-s1.binance.org:8545,https://data-seed-prebsc-2-s1.binance.org:8545

# 合约地址 (请替换为实际地址)
CONTRACT_ADDRESS=0x1234567890123456789012345678901234567890

# 管理员私钥 (生产环境请使用环境变量或密钥管理服务)
ADMIN_PRIVATE_KEY=your_admin_private_key_here_never_commit_this_to_git

# 日志配置
LOG_LEVEL=info
LOG_FILE=./logs/app.log

# 安全配置
CORS_ORIGIN=*
HELMET_ENABLED=true

# 健康检查配置
HEALTH_CHECK_INTERVAL=30000
EOF
    
    print_message ".env 文件创建完成"
}

# 创建 ABI 占位符文件
create_abi_file() {
    print_message "创建 ABI 占位符文件..."
    
    cat > abi/NodeStakingUpgradeable.json << 'EOF'
{
  "abi": [
    {
      "inputs": [],
      "name": "governor",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "activeNodes",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "rewardPerNode",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "tbv",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ],
  "description": "NodeStakingUpgradeable Contract ABI - 请将您的实际合约 ABI 替换此文件内容",
  "version": "1.0.0",
  "note": "这是一个占位符 ABI 文件。请将您的实际 NodeStakingUpgradeable 合约的 ABI 内容复制到此文件中。"
}
EOF
    
    print_message "ABI 占位符文件创建完成"
}

# 创建核心服务器文件
create_server_file() {
    print_message "创建服务器文件..."
    
    cat > server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// 导入自定义模块
import config from './src/config.js';
import logger from './src/logger.js';
import authMiddleware from './src/middleware/auth.js';
import adminRoutes from './src/routes/admin.js';

// 加载环境变量
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 创建 Express 应用
const app = express();

// 基础中间件
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false
}));

app.use(cors({
  origin: config.corsOrigin === '*' ? true : config.corsOrigin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-api-key']
}));

app.use(morgan('combined', {
  stream: {
    write: (message) => logger.info(message.trim())
  }
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 健康检查端点
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version || '1.0.0',
    environment: config.nodeEnv
  });
});

// API 路由
app.use('/api/admin', authMiddleware, adminRoutes);

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

// 404 处理
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
    timestamp: new Date().toISOString()
  });
});

// 全局错误处理
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip
  });

  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: config.nodeEnv === 'production' ? 'Something went wrong' : err.message,
    timestamp: new Date().toISOString()
  });
});

// 启动服务器
const startServer = async () => {
  try {
    // 验证必要的环境变量
    if (!config.apiKey) {
      throw new Error('API_KEY is required');
    }
    
    if (!config.contractAddress) {
      throw new Error('CONTRACT_ADDRESS is required');
    }
    
    if (!config.rpcUrls || config.rpcUrls.length === 0) {
      throw new Error('RPC_URLS is required');
    }

    // 启动 HTTP 服务器
    const server = app.listen(config.port, config.host, () => {
      logger.info(`🚀 Server running on ${config.host}:${config.port}`);
      logger.info(`📊 Environment: ${config.nodeEnv}`);
      logger.info(`🔗 Health check: http://${config.host}:${config.port}/health`);
      logger.info(`🔐 API endpoints: http://${config.host}:${config.port}/api/admin/*`);
    });

    // 优雅关闭处理
    const gracefulShutdown = (signal) => {
      logger.info(`Received ${signal}, shutting down gracefully...`);
      
      server.close((err) => {
        if (err) {
          logger.error('Error during server shutdown:', err);
          process.exit(1);
        }
        
        logger.info('Server closed successfully');
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // 处理未捕获的异常
    process.on('uncaughtException', (err) => {
      logger.error('Uncaught Exception:', err);
      gracefulShutdown('uncaughtException');
    });

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      gracefulShutdown('unhandledRejection');
    });

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// 启动应用
startServer();
EOF
    
    print_message "服务器文件创建完成"
}

# 创建配置文件
create_config_file() {
    print_message "创建配置文件..."
    
    cat > src/config.js << 'EOF'
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// 加载环境变量
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 配置对象
const config = {
  // 服务器配置
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,
  host: process.env.HOST || '0.0.0.0',
  
  // API 安全配置
  apiKey: process.env.API_KEY,
  
  // 区块链配置
  rpcUrls: process.env.RPC_URLS ? 
    process.env.RPC_URLS.split(',').map(url => url.trim()).filter(Boolean) : [],
  contractAddress: process.env.CONTRACT_ADDRESS,
  adminPrivateKey: process.env.ADMIN_PRIVATE_KEY,
  
  // 日志配置
  logLevel: process.env.LOG_LEVEL || 'info',
  logFile: process.env.LOG_FILE || './logs/app.log',
  
  // 安全配置
  corsOrigin: process.env.CORS_ORIGIN || '*',
  helmetEnabled: process.env.HELMET_ENABLED === 'true',
  
  // 健康检查配置
  healthCheckInterval: parseInt(process.env.HEALTH_CHECK_INTERVAL, 10) || 30000,
  
  // 文件路径
  abiPath: join(__dirname, '..', 'abi', 'NodeStakingUpgradeable.json'),
  logsPath: join(__dirname, '..', 'logs'),
  
  // 合约配置
  gasLimit: process.env.GAS_LIMIT || '500000',
  gasPrice: process.env.GAS_PRICE || '5000000000', // 5 gwei
  maxRetries: parseInt(process.env.MAX_RETRIES, 10) || 3,
  retryDelay: parseInt(process.env.RETRY_DELAY, 10) || 1000,
  
  // 网络配置
  networkId: process.env.NETWORK_ID || '97', // BSC 测试网
  chainId: process.env.CHAIN_ID || '0x61', // BSC 测试网 chainId
};

// 验证必要的配置
const validateConfig = () => {
  const required = [
    'apiKey',
    'contractAddress',
    'rpcUrls'
  ];
  
  const missing = required.filter(key => !config[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
  
  // 验证 RPC URLs
  if (config.rpcUrls.length === 0) {
    throw new Error('At least one RPC URL is required');
  }
  
  // 验证合约地址格式
  if (config.contractAddress && !/^0x[a-fA-F0-9]{40}$/.test(config.contractAddress)) {
    throw new Error('Invalid contract address format');
  }
  
  // 验证端口号
  if (config.port < 1 || config.port > 65535) {
    throw new Error('Invalid port number');
  }
  
  return true;
};

// 初始化配置
try {
  validateConfig();
} catch (error) {
  console.error('Configuration validation failed:', error.message);
  process.exit(1);
}

export default config;
EOF
    
    print_message "配置文件创建完成"
}

# 创建日志文件
create_logger_file() {
    print_message "创建日志文件..."
    
    cat > src/logger.js << 'EOF'
import winston from 'winston';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import config from './config.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 确保日志目录存在
const logsDir = join(__dirname, '..', 'logs');
if (!existsSync(logsDir)) {
  mkdirSync(logsDir, { recursive: true });
}

// 自定义日志格式
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.prettyPrint()
);

// 控制台格式
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level}]: ${message}`;
    
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta, null, 2)}`;
    }
    
    return log;
  })
);

// 创建 Winston logger 实例
const logger = winston.createLogger({
  level: config.logLevel || 'info',
  format: logFormat,
  defaultMeta: {
    service: 'node-staking-admin',
    version: '1.0.0'
  },
  transports: [
    // 文件传输 - 所有日志
    new winston.transports.File({
      filename: join(logsDir, 'app.log'),
      maxsize: 20 * 1024 * 1024, // 20MB
      maxFiles: 5,
      tailable: true
    }),
    
    // 文件传输 - 错误日志
    new winston.transports.File({
      filename: join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 20 * 1024 * 1024, // 20MB
      maxFiles: 5,
      tailable: true
    })
  ],
  
  // 异常处理
  exceptionHandlers: [
    new winston.transports.File({
      filename: join(logsDir, 'exceptions.log'),
      maxsize: 20 * 1024 * 1024, // 20MB
      maxFiles: 3,
      tailable: true
    })
  ],
  
  // 未处理的 Promise 拒绝
  rejectionHandlers: [
    new winston.transports.File({
      filename: join(logsDir, 'rejections.log'),
      maxsize: 20 * 1024 * 1024, // 20MB
      maxFiles: 3,
      tailable: true
    })
  ]
});

// 在非生产环境添加控制台输出
if (config.nodeEnv !== 'production') {
  logger.add(new winston.transports.Console({
    format: consoleFormat,
    level: 'debug'
  }));
}

// 添加自定义方法
logger.contract = (message, meta = {}) => {
  logger.info(`[CONTRACT] ${message}`, { ...meta, category: 'contract' });
};

logger.api = (message, meta = {}) => {
  logger.info(`[API] ${message}`, { ...meta, category: 'api' });
};

logger.security = (message, meta = {}) => {
  logger.warn(`[SECURITY] ${message}`, { ...meta, category: 'security' });
};

logger.blockchain = (message, meta = {}) => {
  logger.info(`[BLOCKCHAIN] ${message}`, { ...meta, category: 'blockchain' });
};

logger.transaction = (txHash, message, meta = {}) => {
  logger.info(`[TRANSACTION] ${message}`, { 
    ...meta, 
    category: 'transaction',
    txHash 
  });
};

// 错误日志辅助函数
logger.errorWithContext = (error, context = {}) => {
  logger.error('Application Error', {
    error: error.message,
    stack: error.stack,
    ...context,
    category: 'error'
  });
};

// 导出 logger 实例
export default logger;
EOF
    
    print_message "日志文件创建完成"
}

# 创建中间件文件
create_middleware_file() {
    print_message "创建中间件文件..."
    
    cat > src/middleware/auth.js << 'EOF'
import logger from '../logger.js';
import config from '../config.js';

/**
 * API 密钥认证中间件
 * 支持从请求头 (x-api-key) 或查询参数 (api_key) 获取 API 密钥
 */
const authMiddleware = (req, res, next) => {
  try {
    // 从请求头获取 API 密钥
    const headerApiKey = req.headers['x-api-key'];
    
    // 从查询参数获取 API 密钥
    const queryApiKey = req.query.api_key;
    
    // 获取提供的 API 密钥
    const providedApiKey = headerApiKey || queryApiKey;
    
    // 检查是否提供了 API 密钥
    if (!providedApiKey) {
      logger.security('API key missing', {
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        url: req.originalUrl,
        method: req.method
      });
      
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'API key is required',
        timestamp: new Date().toISOString()
      });
    }
    
    // 验证 API 密钥
    if (providedApiKey !== config.apiKey) {
      logger.security('Invalid API key', {
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        url: req.originalUrl,
        method: req.method,
        providedKey: providedApiKey.substring(0, 8) + '...' // 只记录前8位用于调试
      });
      
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid API key',
        timestamp: new Date().toISOString()
      });
    }
    
    // 记录成功的认证
    logger.security('API authentication successful', {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      url: req.originalUrl,
      method: req.method
    });
    
    // 将认证信息添加到请求对象
    req.auth = {
      authenticated: true,
      apiKey: providedApiKey.substring(0, 8) + '...', // 只存储前8位用于日志
      timestamp: new Date().toISOString()
    };
    
    next();
    
  } catch (error) {
    logger.errorWithContext(error, {
      ip: req.ip,
      url: req.originalUrl,
      method: req.method
    });
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Authentication service error',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * 管理员权限检查中间件
 * 检查是否有管理员私钥配置（用于写操作）
 */
const adminRequiredMiddleware = (req, res, next) => {
  try {
    // 检查是否配置了管理员私钥
    if (!config.adminPrivateKey) {
      logger.security('Admin operation attempted without private key', {
        ip: req.ip,
        url: req.originalUrl,
        method: req.method
      });
      
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Admin private key not configured. Write operations are disabled.',
        timestamp: new Date().toISOString()
      });
    }
    
    // 将管理员信息添加到请求对象
    req.admin = {
      hasPrivateKey: true,
      canWrite: true,
      timestamp: new Date().toISOString()
    };
    
    next();
    
  } catch (error) {
    logger.errorWithContext(error, {
      ip: req.ip,
      url: req.originalUrl,
      method: req.method
    });
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Admin permission check error',
      timestamp: new Date().toISOString()
    });
  }
};

export default authMiddleware;
export {
  authMiddleware,
  adminRequiredMiddleware
};
EOF
    
    print_message "中间件文件创建完成"
}

# 创建服务文件
create_service_file() {
    print_message "创建服务文件..."
    
    cat > src/services/contractService.js << 'EOF'
import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import logger from '../logger.js';
import config from '../config.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * 合约服务类
 * 负责与 NodeStakingUpgradeable 合约的交互
 */
class ContractService {
  constructor() {
    this.provider = null;
    this.signer = null;
    this.contract = null;
    this.contractWithSigner = null;
    this.abi = null;
    this.currentRpcIndex = 0;
    
    this.initialize();
  }

  /**
   * 初始化合约服务
   */
  async initialize() {
    try {
      // 加载 ABI
      await this.loadABI();
      
      // 初始化 provider
      await this.initializeProvider();
      
      // 初始化合约实例
      this.initializeContract();
      
      // 初始化签名器（如果配置了私钥）
      if (config.adminPrivateKey) {
        this.initializeSigner();
      }
      
      logger.contract('Contract service initialized successfully');
      
    } catch (error) {
      logger.errorWithContext(error, { context: 'ContractService.initialize' });
      throw error;
    }
  }

  /**
   * 加载合约 ABI
   */
  async loadABI() {
    try {
      const abiPath = join(__dirname, '..', '..', 'abi', 'NodeStakingUpgradeable.json');
      const abiData = JSON.parse(readFileSync(abiPath, 'utf8'));
      
      // 支持不同的 ABI 格式
      this.abi = abiData.abi || abiData;
      
      if (!this.abi || !Array.isArray(this.abi)) {
        throw new Error('Invalid ABI format');
      }
      
      logger.contract('ABI loaded successfully', { 
        functions: this.abi.filter(item => item.type === 'function').length 
      });
      
    } catch (error) {
      logger.errorWithContext(error, { context: 'loadABI' });
      throw new Error(`Failed to load ABI: ${error.message}`);
    }
  }

  /**
   * 初始化 Provider（支持多 RPC 轮询）
   */
  async initializeProvider() {
    const rpcUrls = config.rpcUrls;
    
    for (let i = 0; i < rpcUrls.length; i++) {
      try {
        const rpcUrl = rpcUrls[i];
        const provider = new ethers.JsonRpcProvider(rpcUrl);
        
        // 测试连接
        const network = await provider.getNetwork();
        const blockNumber = await provider.getBlockNumber();
        
        this.provider = provider;
        this.currentRpcIndex = i;
        
        logger.blockchain('RPC connection established', {
          rpcUrl: rpcUrl.substring(0, 50) + '...',
          networkId: network.chainId.toString(),
          blockNumber,
          rpcIndex: i
        });
        
        return;
        
      } catch (error) {
        logger.blockchain('RPC connection failed', {
          rpcUrl: rpcUrls[i].substring(0, 50) + '...',
          error: error.message,
          rpcIndex: i
        });
        
        // 如果是最后一个 RPC，抛出错误
        if (i === rpcUrls.length - 1) {
          throw new Error('All RPC endpoints failed');
        }
      }
    }
  }

  /**
   * 初始化合约实例
   */
  initializeContract() {
    if (!this.provider || !this.abi || !config.contractAddress) {
      throw new Error('Provider, ABI, or contract address not available');
    }
    
    this.contract = new ethers.Contract(
      config.contractAddress,
      this.abi,
      this.provider
    );
    
    logger.contract('Contract instance created', {
      address: config.contractAddress,
      functions: this.abi.filter(item => item.type === 'function').length
    });
  }

  /**
   * 初始化签名器
   */
  initializeSigner() {
    if (!config.adminPrivateKey) {
      logger.contract('No private key configured, write operations disabled');
      return;
    }
    
    try {
      this.signer = new ethers.Wallet(config.adminPrivateKey, this.provider);
      this.contractWithSigner = this.contract.connect(this.signer);
      
      logger.contract('Signer initialized', {
        address: this.signer.address
      });
      
    } catch (error) {
      logger.errorWithContext(error, { context: 'initializeSigner' });
      throw new Error(`Failed to initialize signer: ${error.message}`);
    }
  }

  /**
   * 获取合约状态
   */
  async getStatus() {
    try {
      const [governor, activeNodes, rewardPerNode, tbv] = await Promise.all([
        this.callMethod('governor'),
        this.callMethod('activeNodes'),
        this.callMethod('rewardPerNode'),
        this.callMethod('tbv')
      ]);
      
      return {
        governor,
        activeNodes: activeNodes.toString(),
        rewardPerNode: rewardPerNode.toString(),
        tbv: tbv.toString()
      };
      
    } catch (error) {
      logger.errorWithContext(error, { context: 'getStatus' });
      throw error;
    }
  }

  /**
   * 调用只读方法
   */
  async callMethod(methodName, params = []) {
    try {
      const method = this.contract[methodName];
      if (!method) {
        throw new Error(`Method ${methodName} not found in contract`);
      }
      
      const result = await method(...params);
      
      logger.contractOperation('Read method called', {
        method: methodName,
        params,
        result: result.toString ? result.toString() : result
      });
      
      return result;
      
    } catch (error) {
      logger.errorWithContext(error, {
        context: 'callMethod',
        method: methodName,
        params
      });
      throw error;
    }
  }

  /**
   * 检查连接状态
   */
  async checkConnection() {
    try {
      const network = await this.provider.getNetwork();
      const blockNumber = await this.provider.getBlockNumber();
      
      return {
        connected: true,
        networkId: network.chainId.toString(),
        blockNumber,
        rpcIndex: this.currentRpcIndex
      };
    } catch (error) {
      return {
        connected: false,
        error: error.message
      };
    }
  }
}

// 创建单例实例
const contractService = new ContractService();

export default contractService;
EOF
    
    print_message "服务文件创建完成"
}

# 创建路由文件
create_routes_file() {
    print_message "创建路由文件..."
    
    cat > src/routes/admin.js << 'EOF'
import express from 'express';
import contractService from '../services/contractService.js';
import logger from '../logger.js';
import { adminRequiredMiddleware } from '../middleware/auth.js';

const router = express.Router();

/**
 * 获取合约状态
 * GET /api/admin/status
 */
router.post('/status', async (req, res) => {
  try {
    logger.api('Getting contract status');
    
    const status = await contractService.getStatus();
    
    logger.api('Contract status retrieved', { status });
    
    res.json({
      success: true,
      data: status,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    logger.errorWithContext(error, { context: 'getStatus' });
    
    res.status(500).json({
      success: false,
      error: 'Failed to get contract status',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * 获取连接状态
 * POST /api/admin/connection
 */
router.post('/connection', async (req, res) => {
  try {
    const connectionStatus = await contractService.checkConnection();
    
    res.json({
      success: true,
      data: connectionStatus,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    logger.errorWithContext(error, { context: 'connection' });
    
    res.status(500).json({
      success: false,
      error: 'Failed to check connection',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

export default router;
EOF
    
    print_message "路由文件创建完成"
}

# 创建工具文件
create_utils_file() {
    print_message "创建工具文件..."
    
    cat > src/utils/validators.js << 'EOF'
import { ethers } from 'ethers';
import logger from '../logger.js';

/**
 * 验证工具类
 * 提供各种数据验证功能
 */
class Validators {
  
  /**
   * 验证以太坊地址格式
   * @param {string} address - 要验证的地址
   * @returns {boolean} - 是否为有效地址
   */
  static isValidAddress(address) {
    try {
      if (!address || typeof address !== 'string') {
        return false;
      }
      
      // 使用 ethers 验证地址
      const checksumAddress = ethers.getAddress(address);
      return !!checksumAddress;
    } catch (error) {
      return false;
    }
  }

  /**
   * 验证并标准化以太坊地址
   * @param {string} address - 要验证的地址
   * @returns {string} - 标准化后的地址
   * @throws {Error} - 如果地址无效
   */
  static validateAndNormalizeAddress(address) {
    if (!address || typeof address !== 'string') {
      throw new Error('Address is required and must be a string');
    }
    
    try {
      return ethers.getAddress(address);
    } catch (error) {
      throw new Error(`Invalid address format: ${address}`);
    }
  }

  /**
   * 验证数值字符串（用于以太币数量）
   * @param {string|number} value - 要验证的数值
   * @param {string} fieldName - 字段名称（用于错误信息）
   * @returns {string} - 验证后的数值字符串
   * @throws {Error} - 如果数值无效
   */
  static validateAmount(value, fieldName = 'amount') {
    if (value === null || value === undefined || value === '') {
      throw new Error(`${fieldName} is required`);
    }
    
    const numValue = typeof value === 'string' ? value : value.toString();
    
    // 检查是否为有效数字
    if (!/^\d+(\.\d+)?$/.test(numValue)) {
      throw new Error(`${fieldName} must be a valid number`);
    }
    
    // 检查是否为负数
    if (parseFloat(numValue) < 0) {
      throw new Error(`${fieldName} must be non-negative`);
    }
    
    // 检查精度（最多18位小数）
    const parts = numValue.split('.');
    if (parts.length === 2 && parts[1].length > 18) {
      throw new Error(`${fieldName} cannot have more than 18 decimal places`);
    }
    
    return numValue;
  }

  /**
   * 记录验证错误
   * @param {Error} error - 验证错误
   * @param {object} context - 上下文信息
   */
  static logValidationError(error, context = {}) {
    logger.security('Validation error', {
      error: error.message,
      ...context
    });
  }
}

export default Validators;
EOF
    
    print_message "工具文件创建完成"
}

# 构建 Docker 镜像
build_docker_image() {
    print_message "构建 Docker 镜像..."
    
    docker build -t node-staking-admin .
    
    if [ $? -eq 0 ]; then
        print_message "Docker 镜像构建成功"
    else
        print_error "Docker 镜像构建失败"
        exit 1
    fi
}

# 启动 Docker 容器
start_docker_container() {
    print_message "启动 Docker 容器..."
    
    # 停止并删除已存在的容器
    docker stop node-staking-admin 2>/dev/null || true
    docker rm node-staking-admin 2>/dev/null || true
    
    # 启动新容器
    docker run -d \
        --name node-staking-admin \
        -p 3000:3000 \
        -v $(pwd)/abi:/app/abi:ro \
        -v $(pwd)/logs:/app/logs \
        --env-file .env \
        node-staking-admin
    
    if [ $? -eq 0 ]; then
        print_message "Docker 容器启动成功"
        print_message "服务地址: http://localhost:3000"
        print_message "健康检查: http://localhost:3000/health"
    else
        print_error "Docker 容器启动失败"
        exit 1
    fi
}

# 显示部署信息
show_deployment_info() {
    echo ""
    print_message "🎉 部署完成！"
    echo ""
    echo -e "${BLUE}服务信息:${NC}"
    echo "  服务地址: http://localhost:3000"
    echo "  健康检查: http://localhost:3000/health"
    echo "  API 文档: http://localhost:3000/api/admin/*"
    echo ""
    echo -e "${BLUE}管理命令:${NC}"
    echo "  查看日志: docker logs -f node-staking-admin"
    echo "  停止服务: docker stop node-staking-admin"
    echo "  重启服务: docker restart node-staking-admin"
    echo "  删除服务: docker rm -f node-staking-admin"
    echo ""
    echo -e "${BLUE}重要提醒:${NC}"
    echo "  1. 请编辑 .env 文件，设置正确的 API_KEY 和 CONTRACT_ADDRESS"
    echo "  2. 请将实际的合约 ABI 放入 abi/NodeStakingUpgradeable.json"
    echo "  3. 生产环境请设置强密码和访问控制"
    echo ""
}

# 主函数
main() {
    print_header
    
    # 检查 Docker
    check_docker
    
    # 创建目录结构
    create_directories
    
    # 创建所有必要文件
    create_package_json
    create_dockerfile
    create_docker_compose
    create_env_file
    create_abi_file
    create_server_file
    create_config_file
    create_logger_file
    create_middleware_file
    create_service_file
    create_routes_file
    create_utils_file
    
    # 构建和启动
    build_docker_image
    start_docker_container
    
    # 显示部署信息
    show_deployment_info
}

# 执行主函数
main "$@"
