# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ Mandatory Tools Usage (必须遵守)

**When working with n8n, you MUST use the available Skills and MCP tools. Do NOT guess or write code manually when a tool or skill exists for that task.**

### Skills Usage Rules

| Task | Required Skill | When to Use |
|------|---------------|-------------|
| Creating/modifying workflows | `n8n-workflow-patterns` | Before any workflow design |
| Writing Code node (JS) | `n8n-code-javascript` | Before writing any JavaScript code |
| Writing Code node (Python) | `n8n-code-python` | Before writing any Python code |
| Using expressions `{{}}` | `n8n-expression-syntax` | Before writing any expression |
| Configuring nodes | `n8n-node-configuration` | Before configuring any node |
| Using MCP tools | `n8n-mcp-tools-expert` | Before using any MCP tool |
| Fixing validation errors | `n8n-validation-expert` | When validation fails |

**How to use skills:**
```
# Read the skill's SKILL.md first
cat .claude/skills/<skill-name>/SKILL.md

# Then read specific topic files as needed
cat .claude/skills/<skill-name>/<topic>.md
```

### MCP Tools Usage Rules

**Always prefer MCP tools over manual configuration.** The MCP server provides direct API access to n8n.

| Task | MCP Tool | Speed |
|------|----------|-------|
| Search for nodes | `search_nodes` | <20ms |
| Get node details | `get_node` | <10ms |
| Validate node config | `validate_node` | <100ms |
| Create workflow | `n8n_create_workflow` | 100-500ms |
| Edit workflow | `n8n_update_partial_workflow` | 50-200ms |
| Deploy template | `n8n_deploy_template` | 200-500ms |
| Validate workflow | `n8n_validate_workflow` | 100-500ms |

**Critical format difference:**
- Search/validate tools: `nodes-base.slack` (short prefix)
- Workflow tools: `n8n-nodes-base.slack` (full prefix)

### Workflow Development Checklist

When building n8n workflows, follow this order:

1. **Read skill** → `n8n-workflow-patterns/SKILL.md` to choose pattern
2. **Search nodes** → `search_nodes({query: "..."})`
3. **Get node details** → `get_node({nodeType: "nodes-base.xxx"})`
4. **Read skill** → `n8n-node-configuration/SKILL.md` for config guidance
5. **Validate config** → `validate_node({nodeType: "...", config: {...}})`
6. **Create workflow** → `n8n_create_workflow({...})`
7. **Read skill** → `n8n-validation-expert/SKILL.md` if errors occur
8. **Activate** → `n8n_update_partial_workflow({operations: [{type: "activateWorkflow"}]})`

## Project Overview

This is a Docker-based production deployment for n8n workflow automation platform. The stack consists of:
- n8n (latest from docker.n8n.io/n8nio/n8n)
- PostgreSQL 15 as the database backend
- Docker Compose orchestration with health checks and auto-restart

## Project Structure

```
n8n/
├── docker-compose.yml          # Docker 服务编排配置
├── .env                        # 环境变量（密码、认证配置）
├── .mcp.json                   # MCP 服务器配置（n8n API 访问）
├── backup.sh                   # 备份脚本（PostgreSQL + n8n 数据 + 本地文件）
├── restore.sh                  # 恢复脚本（按时间戳恢复）
├── setup-cron.sh               # 定时备份设置（每天凌晨 2 点）
├── README.md                   # 详细部署文档
├── CLAUDE.md                   # 本文件
│
├── app/                        # n8n 应用项目
│   ├── claudechangelogRSS/     # Claude 更新日志 RSS 项目
│   └── csdnWrite/              # CSDN 写作项目
│
├── backups/                    # 备份文件存储
│   ├── n8n_db_<timestamp>.sql          # PostgreSQL 数据库备份
│   ├── n8n_data_<timestamp>.tar.gz     # n8n 数据卷备份
│   └── local_files_<timestamp>.tar.gz  # 本地文件备份
│
├── local-files/                # n8n 可访问的本地文件目录（挂载到 /files）
├── data/                       # 数据目录（预留）
├── docs/                       # 文档目录
│   ├── PROJECT_STRUCTURE.md    # 项目结构详解
│   └── SKILLS_QUICK_REFERENCE.md # Skills 快速参考
├── logs/                       # 日志目录（预留）
│
└── .claude/                    # Claude Code 配置
    ├── settings.local.json     # 本地权限配置
    └── skills/                 # n8n 开发技能库
        ├── n8n-workflow-patterns/      # 工作流架构模式
        ├── n8n-code-javascript/        # JavaScript Code 节点
        ├── n8n-code-python/            # Python Code 节点
        ├── n8n-expression-syntax/      # 表达式语法
        ├── n8n-node-configuration/     # 节点配置
        ├── n8n-mcp-tools-expert/       # MCP 工具使用
        └── n8n-validation-expert/      # 工作流验证
```

## Essential Commands

### Service Management
```bash
docker compose up -d          # Start all services
docker compose down           # Stop and remove containers (preserves volumes)
docker compose restart        # Restart services
docker compose ps             # View service status
docker compose logs -f n8n    # Follow n8n logs
docker compose logs -f postgres  # Follow PostgreSQL logs
```

### Backup and Restore
```bash
./backup.sh                   # Full backup: PostgreSQL + n8n data + local files
./restore.sh <YYYYMMDD_HHMMSS>  # Restore from backup timestamp
./setup-cron.sh               # Enable daily 2am auto-backup via crontab
```

### Container Access
```bash
docker compose exec n8n sh                    # Enter n8n container
docker compose exec postgres psql -U n8n -d n8n  # PostgreSQL CLI
```

### Health Checks
```bash
docker compose exec postgres pg_isready -U n8n  # Check PostgreSQL
curl -f http://localhost:5678/healthz            # Check n8n health
```

## Architecture

### Docker Volumes
| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `n8n_data` | `/home/node/.n8n` | n8n workflows, credentials, config |
| `postgres_data` | `/var/lib/postgresql/data` | PostgreSQL data |
| `./local-files` | `/files` | Local file storage accessible by n8n |

### Service Dependencies
- n8n depends on PostgreSQL (uses `condition: service_healthy`)
- PostgreSQL health check: `pg_isready -U n8n` every 10s

### Network Configuration
- n8n Web UI: `http://localhost:5678`
- Default timezone: `Asia/Shanghai`
- Database: `n8n` user, `n8n` database on port 5432

## Configuration

### Environment Variables (.env)
Key variables that must be set:
- `POSTGRES_PASSWORD` - Database password (referenced by both services)
- `N8N_BASIC_AUTH_PASSWORD` - n8n admin login password

Optional webhook/domain configuration (commented out by default):
- `WEBHOOK_URL`, `N8N_HOST`, `N8N_PORT`, `N8N_PROTOCOL`

### Docker Compose Environment Variables

#### Core Settings
| Variable | Value | Purpose |
|----------|-------|---------|
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | `true` | Enforce file permissions |
| `GENERIC_TIMEZONE` / `TZ` | `Asia/Shanghai` | Timezone configuration |
| `NODE_ENV` | `production` | Node.js environment |

#### Feature Unlock Settings
| Variable | Value | Purpose |
|----------|-------|---------|
| `N8N_RUNNERS_ENABLED` | `true` | Enable task runners |
| `N8N_BLOCK_FS_WRITE_ACCESS` | `false` | Allow filesystem write access |
| `NODE_FUNCTION_ALLOW_BUILTIN` | `*` | Allow all built-in Node.js modules |
| `NODE_FUNCTION_ALLOW_EXTERNAL` | `*` | Allow all external npm packages |
| `N8N_UNVERIFIED_PACKAGES_ENABLED` | `true` | Enable unverified community packages |
| `N8N_ENABLE_EXECUTE_COMMAND` | `true` | Enable Execute Command node |
| `N8N_BLOCK_ENV_VARS_IN_EXECUTE_COMMAND` | `false` | Allow env vars in Execute Command |
| `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` | `true` | Allow community packages as AI tools |
| `NODE_EXCLUDE` | `[]` | No excluded nodes |

#### Database Settings
| Variable | Value | Purpose |
|----------|-------|---------|
| `DB_TYPE` | `postgresdb` | Database type |
| `DB_POSTGRESDB_*` | - | PostgreSQL connection details |

#### Security Settings
| Variable | Value | Purpose |
|----------|-------|---------|
| `N8N_BASIC_AUTH_ACTIVE` | `true` | Enable basic auth |
| `N8N_BASIC_AUTH_USER` | `admin` | Admin username |
| `N8N_BASIC_AUTH_PASSWORD` | from `.env` | Admin password |

### Important Safety Notes
- **Never use `docker compose down -v`** - this deletes all data volumes
- Always backup before PostgreSQL version upgrades
- Backup retention: 30 days automatic cleanup in `backup.sh`

## Claude Code Skills for n8n Development

The `.claude/skills/` directory contains 7 specialized skills for n8n workflow development.

> **⚠️ IMPORTANT**: You MUST read the relevant skill's `SKILL.md` file before performing any n8n-related task. Skills contain critical patterns, anti-patterns, and best practices that prevent common errors.

### How to Use Skills

1. **Identify the task type** (workflow design, code writing, node configuration, etc.)
2. **Read the skill's `SKILL.md`** for overview and guidelines
3. **Read specific topic files** for detailed patterns
4. **Apply the patterns** in your implementation

```bash
# Example: Before writing JavaScript Code node
cat .claude/skills/n8n-code-javascript/SKILL.md
cat .claude/skills/n8n-code-javascript/COMMON_PATTERNS.md

# Example: Before configuring a node
cat .claude/skills/n8n-node-configuration/SKILL.md
cat .claude/skills/n8n-node-configuration/OPERATION_PATTERNS.md
```

### 1. n8n-workflow-patterns (核心：工作流架构)
**何时使用**: 创建新工作流、设计工作流架构、选择工作流模式时必须阅读

6 种核心工作流模式，覆盖 90%+ 使用场景：

| 模式 | 场景 | 示例 |
|------|------|------|
| **Webhook Processing** | 接收 HTTP 请求 | 表单提交 → 处理 → 通知 |
| **HTTP API Integration** | 调用外部 API | 获取数据 → 转换 → 存储 |
| **Database Operations** | 数据库读写同步 | 定时查询 → 转换 → 写入 |
| **AI Agent Workflow** | AI 代理工作流 | 聊天 → AI Agent (模型+工具+内存) → 输出 |
| **Scheduled Tasks** | 定时任务 | 每日报表、数据同步 |
| **Batch Processing** | 大数据集分批处理 | SplitInBatches 循环处理 |

**关键文件**：
- `SKILL.md` - 模式选择指南、工作流创建清单、数据流模式
- `webhook_processing.md` - Webhook 数据结构、响应处理
- `http_api_integration.md` - REST API、认证、分页、重试
- `database_operations.md` - 查询、同步、事务、批量处理
- `ai_agent_workflow.md` - AI 代理、工具、内存、Langchain 节点
- `scheduled_tasks.md` - Cron 调度、报表、维护任务

### 2. n8n-code-javascript (核心：JavaScript 代码)
**何时使用**: 编写 JavaScript Code 节点时必须阅读，特别是数据访问和返回格式

Code 节点的 JavaScript 开发指南：

**关键概念**：
- 两种模式：`Run Once for All Items`（推荐）vs `Run Once for Each Item`
- 数据访问：`$input.all()`, `$input.first()`, `$input.item`
- 返回格式：`[{json: {...}}]`（必须）
- Webhook 数据：`$json.body.field`（不是 `$json.field`）

**关键文件**：
- `SKILL.md` - 模式选择、数据访问、返回格式、错误预防
- `COMMON_PATTERNS.md` - 10 种生产环境模式
- `DATA_ACCESS.md` - 完整数据访问指南
- `ERROR_PATTERNS.md` - 常见错误和解决方案
- `BUILTIN_FUNCTIONS.md` - 内置函数参考

**关键模式**：
```javascript
// SplitInBatches 跨迭代数据累积
// BEFORE loop:
const staticData = $getWorkflowStaticData('global');
staticData.results = [];

// INSIDE loop:
staticData.results.push(processedData);

// AFTER loop:
const allResults = staticData.results;
```

### 3. n8n-expression-syntax (核心：表达式语法)
**何时使用**: 使用 `{{}}` 表达式、引用其他节点数据、处理 Webhook 数据时必须阅读

n8n 表达式语法指南：

**关键规则**：
- 动态内容必须用 `{{}}` 包裹
- Webhook 数据在 `.body` 下：`{{$json.body.field}}`
- Code 节点不用 `{{}}`，直接用 JavaScript
- 节点名有空格必须用引号：`{{$node["HTTP Request"].json.data}}`

**关键文件**：
- `SKILL.md` - 格式、核心变量、常见模式、验证规则
- `COMMON_MISTAKES.md` - 完整错误目录
- `EXAMPLES.md` - 真实工作流示例

### 4. n8n-node-configuration (节点配置)
**何时使用**: 配置任何节点属性、理解字段依赖关系、处理 displayOptions 时必须阅读

Operation-aware 节点配置指南：

**关键概念**：
- 渐进式发现：先用 `get_node({detail: "standard"})`（95% 场景够用）
- 属性依赖：字段可见性由 `displayOptions` 控制
- Operation-specific：不同操作需要不同字段

**关键文件**：
- `SKILL.md` - 配置流程、属性依赖、常见节点模式
- `DEPENDENCIES.md` - 深入属性依赖和 displayOptions
- `OPERATION_PATTERNS.md` - 按节点类型的配置模式

### 5. n8n-mcp-tools-expert (MCP 工具使用)
**何时使用**: 使用任何 MCP 工具前必须阅读，特别是工具选择和格式差异

n8n-mcp MCP 服务器工具使用指南：

**关键工具**：
| 工具 | 用途 | 速度 |
|------|------|------|
| `search_nodes` | 搜索节点 | <20ms |
| `get_node` | 获取节点详情 | <10ms |
| `validate_node` | 验证节点配置 | <100ms |
| `n8n_create_workflow` | 创建工作流 | 100-500ms |
| `n8n_update_partial_workflow` | 编辑工作流（最常用） | 50-200ms |
| `n8n_deploy_template` | 部署模板 | 200-500ms |

**关键格式差异**：
- 搜索/验证工具：`nodes-base.slack`（短前缀）
- 工作流工具：`n8n-nodes-base.slack`（完整前缀）

**关键文件**：
- `SKILL.md` - 工具分类、选择指南、常见错误
- `SEARCH_GUIDE.md` - 节点发现工具详解
- `VALIDATION_GUIDE.md` - 验证工具详解
- `WORKFLOW_GUIDE.md` - 工作流管理工具详解

### 6. n8n-validation-expert (工作流验证)
**何时使用**: 遇到验证错误、需要理解错误含义、需要自动修复时必须阅读

验证错误解释和修复指南：

**关键概念**：
- 验证是迭代过程：平均 2-3 轮（23s 思考 + 58s 修复）
- 4 种验证配置：`minimal`, `runtime`（推荐）, `ai-friendly`, `strict`
- 自动修复：操作符结构问题自动修复
- 误报识别：学会识别可接受的警告

**关键文件**：
- `SKILL.md` - 错误严重级别、验证循环、验证配置
- `ERROR_CATALOG.md` - 完整错误类型目录
- `FALSE_POSITIVES.md` - 何时警告是可接受的

### 7. n8n-code-python (Python 代码)
**何时使用**: 编写 Python Code 节点时必须阅读

Python Code 节点开发指南（结构类似 JavaScript）

## Workflow Development Workflow

使用 Claude Code 开发 n8n 工作流的标准流程：

### 1. 规划阶段
- 确定工作流模式（Webhook、API、Database、AI、Scheduled、Batch）
- 使用 `n8n-workflow-patterns` skill 选择合适模式
- 列出所需节点

### 2. 发现阶段
```javascript
// 搜索节点
search_nodes({query: "slack"})

// 获取节点详情（默认 standard 够用）
get_node({nodeType: "nodes-base.slack"})

// 验证节点配置
validate_node({nodeType: "nodes-base.slack", config: {...}, profile: "runtime"})
```

### 3. 构建阶段
```javascript
// 创建工作流
n8n_create_workflow({name: "My Workflow", nodes: [...], connections: {...}})

// 迭代编辑（平均 56s 间隔）
n8n_update_partial_workflow({
  id: "workflow-id",
  intent: "Add webhook trigger",
  operations: [{type: "addNode", node: {...}}]
})

// 验证工作流
n8n_validate_workflow({id: "workflow-id"})
```

### 4. 部署阶段
```javascript
// 激活工作流
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{type: "activateWorkflow"}]
})
```

## MCP Server Configuration

An n8n MCP server is configured in `.mcp.json` at `http://localhost:5678/mcp-server/http`. This enables direct n8n API access for workflow management via Claude Code.

### Available MCP Tools

#### Node Discovery Tools
| Tool | Purpose | Example |
|------|---------|---------|
| `search_nodes` | Search for nodes by keyword | `search_nodes({query: "slack"})` |
| `get_node` | Get node details and properties | `get_node({nodeType: "nodes-base.slack"})` |
| `list_nodes` | List all available nodes | `list_nodes({})` |

#### Node Configuration Tools
| Tool | Purpose | Example |
|------|---------|---------|
| `validate_node` | Validate node configuration | `validate_node({nodeType: "nodes-base.slack", config: {...}})` |
| `search_node_properties` | Search for specific properties | `search_node_properties({nodeType: "...", query: "channel"})` |

#### Workflow Management Tools
| Tool | Purpose | Example |
|------|---------|---------|
| `n8n_create_workflow` | Create new workflow | `n8n_create_workflow({name: "...", nodes: [...], connections: {...}})` |
| `n8n_update_partial_workflow` | Edit existing workflow | `n8n_update_partial_workflow({id: "...", operations: [...]})` |
| `n8n_get_workflow` | Get workflow details | `n8n_get_workflow({id: "..."})` |
| `n8n_list_workflows` | List all workflows | `n8n_list_workflows({})` |
| `n8n_delete_workflow` | Delete workflow | `n8n_delete_workflow({id: "..."})` |
| `n8n_validate_workflow` | Validate workflow | `n8n_validate_workflow({id: "..."})` |
| `n8n_deploy_template` | Deploy from template | `n8n_deploy_template({templateId: "..."})` |

#### Data & Credentials Tools
| Tool | Purpose | Example |
|------|---------|---------|
| `n8n_manage_datatable` | Manage data tables | `n8n_manage_datatable({operation: "create", ...})` |
| `n8n_manage_credentials` | Manage credentials | `n8n_manage_credentials({operation: "create", ...})` |
| `n8n_audit_instance` | Security audit | `n8n_audit_instance({})` |

### MCP Tool Usage Patterns

**Pattern 1: Search → Get → Configure → Validate**
```javascript
// 1. Search for node
const nodes = await search_nodes({query: "http"})

// 2. Get node details
const nodeInfo = await get_node({nodeType: "nodes-base.httpRequest"})

// 3. Configure node (use short prefix for validation)
const validation = await validate_node({
  nodeType: "nodes-base.httpRequest",
  config: {method: "GET", url: "https://api.example.com"}
})

// 4. Use in workflow (full prefix)
await n8n_create_workflow({
  name: "My Workflow",
  nodes: [{type: "n8n-nodes-base.httpRequest", ...}]
})
```

**Pattern 2: Iterative Workflow Building**
```javascript
// Create initial workflow
const workflow = await n8n_create_workflow({name: "...", nodes: [...]})

// Add nodes incrementally
await n8n_update_partial_workflow({
  id: workflow.id,
  intent: "Add HTTP trigger",
  operations: [{type: "addNode", node: {...}}]
})

// Validate after each change
await n8n_validate_workflow({id: workflow.id})

// Activate when ready
await n8n_update_partial_workflow({
  id: workflow.id,
  operations: [{type: "activateWorkflow"}]
})
```

### Common MCP Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid node type` | Wrong prefix | Use `nodes-base.xxx` for search/validate, `n8n-nodes-base.xxx` for workflow operations |
| `Missing required field` | Incomplete config | Check `get_node` response for required properties |
| `Workflow not found` | Wrong ID | Use `n8n_list_workflows` to find correct ID |
| `Validation failed` | Config error | Read `n8n-validation-expert` skill for error interpretation

## Backup Files

Backups are stored in `./backups/` with naming pattern:
- `n8n_db_<timestamp>.sql` - PostgreSQL dump
- `n8n_data_<timestamp>.tar.gz` - n8n volume snapshot
- `local_files_<timestamp>.tar.gz` - Local files archive

## Quick Reference: Task → Tool Mapping

| I want to... | Tool/Skill to use |
|--------------|-------------------|
| Create a new workflow | `n8n_create_workflow` + `n8n-workflow-patterns` skill |
| Add a node to workflow | `n8n_update_partial_workflow` + `n8n-node-configuration` skill |
| Find what node to use | `search_nodes` + `get_node` |
| Write JavaScript code | `n8n-code-javascript` skill |
| Write Python code | `n8n-code-python` skill |
| Use expressions `{{}}` | `n8n-expression-syntax` skill |
| Fix validation errors | `n8n-validation-expert` skill + `n8n_validate_workflow` |
| Deploy a template | `n8n_deploy_template` |
| Manage credentials | `n8n_manage_credentials` |
| Run security audit | `n8n_audit_instance` |

## Common Pitfalls to Avoid

1. **Don't guess node properties** → Use `get_node` to get accurate schema
2. **Don't use wrong prefix** → `nodes-base.xxx` for search/validate, `n8n-nodes-base.xxx` for workflows
3. **Don't skip validation** → Always `validate_node` before adding to workflow
4. **Don't ignore skills** → Skills contain critical patterns that prevent errors
5. **Don't write expressions blindly** → Read `n8n-expression-syntax` skill for correct format
