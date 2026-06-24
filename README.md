# n8n Docker 生产环境部署

基于 Docker Compose 的 n8n 工作流自动化平台生产部署方案。

## 技术栈

- **n8n** - 工作流自动化平台（最新版）
- **PostgreSQL 15** - 数据库后端
- **Docker Compose** - 服务编排

## 快速开始

### 1. 配置环境变量

复制并编辑 `.env` 文件：

```bash
cp .env.example .env
# 编辑 .env 设置密码
```

关键配置项：
- `POSTGRES_PASSWORD` - PostgreSQL 数据库密码
- `N8N_BASIC_AUTH_PASSWORD` - n8n 管理员登录密码

### 2. 启动服务

```bash
docker compose up -d
```

### 3. 访问 n8n

打开浏览器访问：`http://localhost:5678`

使用 `.env` 中配置的用户名/密码登录。

## 项目结构

```
n8n/
├── docker-compose.yml    # Docker 服务编排
├── .env                  # 环境变量配置
├── .mcp.json            # MCP 服务器配置
├── backup.sh            # 备份脚本
├── restore.sh           # 恢复脚本
├── setup-cron.sh        # 定时备份设置
├── app/                 # n8n 应用项目
├── backups/             # 备份文件存储
├── local-files/         # n8n 本地文件目录
├── data/                # 数据目录
├── docs/                # 文档目录
└── logs/                # 日志目录
```

## 常用命令

### 服务管理

```bash
# 启动服务
docker compose up -d

# 停止服务（保留数据）
docker compose down

# 重启服务
docker compose restart

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f n8n
docker compose logs -f postgres
```

### 备份与恢复

```bash
# 完整备份（PostgreSQL + n8n 数据 + 本地文件）
./backup.sh

# 恢复指定时间点的备份
./restore.sh 20260610_175000

# 设置每天凌晨 2 点自动备份
./setup-cron.sh
```

### 容器操作

```bash
# 进入 n8n 容器
docker compose exec n8n sh

# 进入 PostgreSQL 命令行
docker compose exec postgres psql -U n8n -d n8n

# 检查 PostgreSQL 健康状态
docker compose exec postgres pg_isready -U n8n

# 检查 n8n 健康状态
curl -f http://localhost:5678/healthz
```

## 环境变量说明

### 核心配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `POSTGRES_PASSWORD` | - | PostgreSQL 数据库密码 |
| `N8N_BASIC_AUTH_USER` | `admin` | n8n 管理员用户名 |
| `N8N_BASIC_AUTH_PASSWORD` | - | n8n 管理员密码 |

### 功能解锁配置

| 变量 | 值 | 说明 |
|------|-----|------|
| `N8N_RUNNERS_ENABLED` | `true` | 启用任务运行器 |
| `N8N_BLOCK_FS_WRITE_ACCESS` | `false` | 允许文件系统写入 |
| `NODE_FUNCTION_ALLOW_BUILTIN` | `*` | 允许所有内置模块 |
| `NODE_FUNCTION_ALLOW_EXTERNAL` | `*` | 允许所有外部模块 |
| `N8N_UNVERIFIED_PACKAGES_ENABLED` | `true` | 启用未验证的社区包 |
| `N8N_ENABLE_EXECUTE_COMMAND` | `true` | 允许执行命令节点 |
| `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` | `true` | 允许社区包作为工具 |

### Webhook/域名配置（可选）

如果需要外部访问，取消注释并配置：

```env
WEBHOOK_URL=https://your-domain.com/
N8N_HOST=your-domain.com
N8N_PORT=5678
N8N_PROTOCOL=https
```

## Docker 卷

| 卷名 | 容器路径 | 用途 |
|------|----------|------|
| `n8n_data` | `/home/node/.n8n` | n8n 工作流、凭证、配置 |
| `postgres_data` | `/var/lib/postgresql/data` | PostgreSQL 数据 |
| `./local-files` | `/files` | n8n 可访问的本地文件 |

## 备份策略

- **频率**：每天凌晨 2 点自动备份（需运行 `setup-cron.sh`）
- **保留**：30 天自动清理
- **内容**：
  - PostgreSQL 数据库转储
  - n8n 数据卷快照
  - 本地文件目录

## 安全注意事项

> **警告**：永远不要使用 `docker compose down -v`，这会删除所有数据卷！

- 生产环境必须设置强密码
- 建议通过反向代理（Nginx）启用 HTTPS
- 升级 PostgreSQL 版本前必须备份
- `.env` 文件包含敏感信息，已在 `.gitignore` 中排除

## 故障排查

### n8n 无法启动

```bash
# 查看日志
docker compose logs n8n

# 检查 PostgreSQL 是否就绪
docker compose exec postgres pg_isready -U n8n
```

### 数据库连接失败

```bash
# 检查 PostgreSQL 容器状态
docker compose ps postgres

# 测试数据库连接
docker compose exec postgres psql -U n8n -d n8n -c "SELECT 1;"
```

### 健康检查

```bash
# 检查所有服务状态
docker compose ps

# 检查 n8n 健康端点
curl http://localhost:5678/healthz
```

## 相关文档

- [项目结构详解](docs/PROJECT_STRUCTURE.md)
- [Skills 快速参考](docs/SKILLS_QUICK_REFERENCE.md)
- [n8n 官方文档](https://docs.n8n.io)
- [n8n 社区论坛](https://community.n8n.io)

## 许可证

n8n 使用 [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md)。
