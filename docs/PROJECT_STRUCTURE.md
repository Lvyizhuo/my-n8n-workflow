# n8n 项目结构详解

本文档详细说明项目的目录结构、文件用途和组件关系。

## 目录树

```
n8n/
├── docker-compose.yml          # Docker 服务编排
├── .env                        # 环境变量配置
├── .mcp.json                   # MCP 服务器配置
├── backup.sh                   # 备份脚本
├── restore.sh                  # 恢复脚本
├── setup-cron.sh               # 定时任务设置
├── README.md                   # 部署文档
├── CLAUDE.md                   # Claude Code 指南
│
├── backups/                    # 备份文件存储
│   ├── n8n_db_<timestamp>.sql
│   ├── n8n_data_<timestamp>.tar.gz
│   └── local_files_<timestamp>.tar.gz
│
├── local-files/                # n8n 本地文件目录
├── data/                       # 数据目录（预留）
├── docs/                       # 文档目录
│   └── PROJECT_STRUCTURE.md    # 本文件
├── logs/                       # 日志目录（预留）
│
└── .claude/                    # Claude Code 配置
    ├── settings.local.json     # 权限配置
    └── skills/                 # n8n 开发技能库
        ├── n8n-workflow-patterns/
        ├── n8n-code-javascript/
        ├── n8n-code-python/
        ├── n8n-expression-syntax/
        ├── n8n-node-configuration/
        ├── n8n-mcp-tools-expert/
        └── n8n-validation-expert/
```

## 核心配置文件

### docker-compose.yml
Docker Compose 编排文件，定义两个服务：

**postgres 服务**：
- 镜像：`postgres:15`
- 容器名：`n8n-postgres`
- 数据卷：`postgres_data:/var/lib/postgresql/data`
- 健康检查：`pg_isready -U n8n`（10s 间隔）

**n8n 服务**：
- 镜像：`docker.n8n.io/n8nio/n8n`
- 容器名：`n8n`
- 端口：`5678:5678`
- 数据卷：
  - `n8n_data:/home/node/.n8n`（工作流、凭证、配置）
  - `./local-files:/files`（本地文件）
- 依赖：postgres（条件：service_healthy）
- 时区：`Asia/Shanghai`

### .env
环境变量配置文件，包含：
- `POSTGRES_PASSWORD` - 数据库密码（两个服务共用）
- `N8N_BASIC_AUTH_PASSWORD` - n8n 管理员密码
- `GENERIC_TIMEZONE` / `TZ` - 时区配置
- 可选：Webhook/域名配置（默认注释）

### .mcp.json
MCP 服务器配置，用于 Claude Code 直接访问 n8n API：
- 服务器地址：`http://localhost:5678/mcp-server/http`
- 认证方式：Bearer Token（JWT）

## 备份系统

### backup.sh
一键备份脚本，备份内容：
1. PostgreSQL 数据库（pg_dump）
2. n8n 数据卷（docker volume → tar.gz）
3. 本地文件目录（tar.gz）
4. 自动清理 30 天前的备份

### restore.sh
恢复脚本，使用方法：
```bash
./restore.sh <timestamp>  # 例如：./restore.sh 20260610_175112
```

恢复流程：
1. 停止 n8n 服务
2. 恢复 PostgreSQL 数据库
3. 恢复 n8n 数据卷（如果存在）
4. 恢复本地文件（如果存在）
5. 重启 n8n 服务

### setup-cron.sh
设置定时备份（每天凌晨 2 点），通过 crontab 实现。

## Claude Code Skills 详解

### n8n-workflow-patterns/
**用途**：工作流架构模式参考

**6 种核心模式**：

1. **Webhook Processing**（最常用）
   - 场景：接收 HTTP 请求
   - 模式：Webhook → 验证 → 转换 → 响应/通知
   - 文件：`webhook_processing.md`

2. **HTTP API Integration**
   - 场景：调用外部 REST API
   - 模式：触发器 → HTTP Request → 转换 → 动作 → 错误处理
   - 文件：`http_api_integration.md`

3. **Database Operations**
   - 场景：数据库读写同步
   - 模式：定时 → 查询 → 转换 → 写入 → 验证
   - 文件：`database_operations.md`

4. **AI Agent Workflow**
   - 场景：AI 代理工作流
   - 模式：触发器 → AI Agent（模型 + 工具 + 内存）→ 输出
   - 文件：`ai_agent_workflow.md`

5. **Scheduled Tasks**
   - 场景：定时任务
   - 模式：定时 → 获取 → 处理 → 交付 → 日志
   - 文件：`scheduled_tasks.md`

6. **Batch Processing**
   - 场景：大数据集分批处理
   - 模式：准备 → SplitInBatches → 逐批处理 → 累积 → 聚合
   - 内嵌在 `SKILL.md` 中

**关键文件**：
- `SKILL.md` - 模式选择指南、工作流创建清单、数据流模式、集成注意事项

### n8n-code-javascript/
**用途**：JavaScript Code 节点开发

**关键概念**：

1. **两种执行模式**
   - `Run Once for All Items`（推荐）：代码执行一次，处理所有项目
   - `Run Once for Each Item`：代码对每个项目执行一次

2. **数据访问**
   - `$input.all()` - 获取所有项目
   - `$input.first()` - 获取第一个项目
   - `$input.item` - 获取当前项目（仅 Each Item 模式）
   - `$node["Node Name"].json` - 引用其他节点

3. **返回格式**（必须）
   ```javascript
   // 正确
   return [{json: {field: value}}];

   // 错误
   return {field: value};  // 缺少数组包装
   return [{field: value}];  // 缺少 json 包装
   ```

4. **Webhook 数据结构**
   ```javascript
   // 错误
   const name = $json.name;

   // 正确
   const name = $json.body.name;
   ```

5. **SplitInBatches 跨迭代数据**
   ```javascript
   // 循环前：重置累加器
   const staticData = $getWorkflowStaticData('global');
   staticData.results = [];

   // 循环内：累积数据
   staticData.results.push(processedData);

   // 循环后：读取累积数据
   const allResults = staticData.results;
   ```

**关键文件**：
- `SKILL.md` - 完整指南（模式选择、数据访问、返回格式、错误预防）
- `COMMON_PATTERNS.md` - 10 种生产环境模式
- `DATA_ACCESS.md` - 数据访问详解
- `ERROR_PATTERNS.md` - 常见错误和解决方案
- `BUILTIN_FUNCTIONS.md` - 内置函数参考（$helpers, DateTime, $jmespath）

### n8n-expression-syntax/
**用途**：n8n 表达式语法

**核心规则**：

1. **表达式格式**
   ```
   ✅ {{$json.field}}
   ❌ $json.field  （缺少 {{}}）
   ❌ {$json.field}  （单括号）
   ```

2. **Webhook 数据**
   ```
   ❌ {{$json.name}}
   ✅ {{$json.body.name}}
   ```

3. **节点引用**
   ```
   ✅ {{$node["HTTP Request"].json.data}}
   ❌ {{$node.HTTP Request.json.data}}  （空格需要引号）
   ```

4. **Code 节点不用表达式**
   ```javascript
   // Code 节点中
   ❌ const name = '={{$json.name}}';
   ✅ const name = $json.name;
   ```

**关键文件**：
- `SKILL.md` - 格式、核心变量、常见模式、验证规则
- `COMMON_MISTAKES.md` - 完整错误目录和修复方法
- `EXAMPLES.md` - 真实工作流示例

### n8n-node-configuration/
**用途**：节点配置指南

**关键概念**：

1. **渐进式发现**
   - `get_node({detail: "standard"})` - 默认，95% 场景够用
   - `get_node({mode: "search_properties", propertyQuery: "..."})` - 查找特定字段
   - `get_node({detail: "full"})` - 完整 schema（谨慎使用）

2. **属性依赖**
   - 字段可见性由 `displayOptions` 控制
   - 例：HTTP Request 的 `body` 字段仅在 `sendBody=true` 且 `method=POST/PUT/PATCH` 时显示

3. **Operation-specific 配置**
   - 不同操作需要不同字段
   - 例：Slack `post` 需要 `channel` + `text`，`update` 需要 `messageId` + `text`

**关键文件**：
- `SKILL.md` - 配置流程、属性依赖、常见节点模式
- `DEPENDENCIES.md` - 深入属性依赖和 displayOptions
- `OPERATION_PATTERNS.md` - 按节点类型的配置模式

### n8n-mcp-tools-expert/
**用途**：n8n-mcp MCP 工具使用指南

**关键工具**：

| 工具 | 用途 | 速度 |
|------|------|------|
| `search_nodes` | 搜索节点 | <20ms |
| `get_node` | 获取节点详情 | <10ms |
| `validate_node` | 验证节点配置 | <100ms |
| `n8n_create_workflow` | 创建工作流 | 100-500ms |
| `n8n_update_partial_workflow` | 编辑工作流 | 50-200ms |
| `n8n_validate_workflow` | 验证工作流 | 100-500ms |
| `n8n_deploy_template` | 部署模板 | 200-500ms |
| `n8n_manage_datatable` | 管理数据表 | 50-500ms |
| `n8n_manage_credentials` | 管理凭证 | 50-500ms |
| `n8n_audit_instance` | 安全审计 | 500-5000ms |

**关键格式差异**：
```javascript
// 搜索/验证工具：短前缀
get_node({nodeType: "nodes-base.slack"})
validate_node({nodeType: "nodes-base.slack", config: {...}})

// 工作流工具：完整前缀
n8n_create_workflow({nodes: [{type: "n8n-nodes-base.slack", ...}]})
n8n_update_partial_workflow({operations: [{type: "addNode", node: {type: "n8n-nodes-base.slack"}}]})
```

**关键文件**：
- `SKILL.md` - 工具分类、选择指南、常见错误、模板使用
- `SEARCH_GUIDE.md` - 节点发现工具详解
- `VALIDATION_GUIDE.md` - 验证工具详解
- `WORKFLOW_GUIDE.md` - 工作流管理工具详解

### n8n-validation-expert/
**用途**：验证错误解释和修复

**关键概念**：

1. **验证是迭代过程**
   - 平均 2-3 轮验证-修复循环
   - 23s 思考错误 + 58s 修复

2. **4 种验证配置**
   - `minimal` - 仅必填字段（最快）
   - `runtime` - 推荐，平衡（默认）
   - `ai-friendly` - 减少误报
   - `strict` - 最严格（生产环境）

3. **错误严重级别**
   - `errors` - 必须修复（阻塞执行）
   - `warnings` - 应该修复（不阻塞）
   - `suggestions` - 可选改进

4. **自动修复**
   - 操作符结构问题自动修复
   - 二元操作符：移除 `singleValue`
   - 一元操作符：添加 `singleValue: true`

5. **误报识别**
   - "Missing error handling" - 简单工作流可接受
   - "No retry logic" - 幂等操作可接受
   - "Missing rate limiting" - 内部 API 可接受

**关键文件**：
- `SKILL.md` - 错误严重级别、验证循环、验证配置、自动修复
- `ERROR_CATALOG.md` - 完整错误类型目录
- `FALSE_POSITIVES.md` - 何时警告是可接受的

### n8n-code-python/
**用途**：Python Code 节点开发

结构类似 `n8n-code-javascript/`，但使用 Python 语法。

## 数据流关系

```
用户请求
    ↓
Claude Code
    ↓
MCP Server (.mcp.json)
    ↓
n8n API (localhost:5678)
    ↓
n8n 服务 (docker-compose.yml)
    ↓
PostgreSQL 数据库
    ↓
Docker Volumes (n8n_data, postgres_data)
```

## 开发工作流

### 1. 规划
- 确定工作流模式（参考 `n8n-workflow-patterns`）
- 列出所需节点

### 2. 发现
```javascript
search_nodes({query: "keyword"})
get_node({nodeType: "nodes-base.xxx"})
```

### 3. 配置
```javascript
validate_node({nodeType: "nodes-base.xxx", config: {...}, profile: "runtime"})
```

### 4. 构建
```javascript
n8n_create_workflow({name: "...", nodes: [...], connections: {...}})
n8n_update_partial_workflow({id: "...", operations: [...]})
```

### 5. 验证
```javascript
n8n_validate_workflow({id: "..."})
```

### 6. 部署
```javascript
n8n_update_partial_workflow({id: "...", operations: [{type: "activateWorkflow"}]})
```

## 备份策略

- **频率**：每天凌晨 2 点自动备份
- **保留**：30 天自动清理
- **内容**：PostgreSQL + n8n 数据卷 + 本地文件
- **位置**：`./backups/` 目录

## 安全注意事项

- **永远不要**使用 `docker compose down -v`（会删除数据卷）
- **升级前**必须备份数据库
- **密码**在 `.env` 中配置，不要硬编码
- **HTTPS** 通过反向代理（Nginx）配置
