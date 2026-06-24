# n8n Claude Code Skills 快速参考

## 技能总览

| 技能 | 用途 | 何时使用 |
|------|------|----------|
| `n8n-workflow-patterns` | 工作流架构模式 | 设计工作流结构、选择模式 |
| `n8n-code-javascript` | JavaScript Code 节点 | 编写 Code 节点、数据转换 |
| `n8n-code-python` | Python Code 节点 | 编写 Python Code 节点 |
| `n8n-expression-syntax` | 表达式语法 | 配置节点字段、引用数据 |
| `n8n-node-configuration` | 节点配置 | 配置节点参数、理解依赖 |
| `n8n-mcp-tools-expert` | MCP 工具使用 | 搜索节点、创建工作流 |
| `n8n-validation-expert` | 工作流验证 | 修复验证错误、理解警告 |

## 快速决策树

```
我要做什么？
│
├─ 设计工作流结构 → n8n-workflow-patterns
│
├─ 写代码节点
│  ├─ JavaScript → n8n-code-javascript
│  └─ Python → n8n-code-python
│
├─ 配置节点字段 → n8n-expression-syntax + n8n-node-configuration
│
├─ 搜索/创建/编辑工作流 → n8n-mcp-tools-expert
│
└─ 修复验证错误 → n8n-validation-expert
```

## 核心概念速查

### 1. 工作流模式（n8n-workflow-patterns）

| 模式 | 触发器 | 典型流程 |
|------|--------|----------|
| Webhook | Webhook 节点 | Webhook → 验证 → 转换 → 响应 |
| API Integration | Schedule/Manual | HTTP Request → 转换 → 存储 |
| Database | Schedule | 查询 → 转换 → 写入 |
| AI Agent | Webhook | AI Agent (模型+工具+内存) |
| Scheduled | Schedule | 定时 → 获取 → 处理 → 交付 |
| Batch | Manual/Schedule | SplitInBatches → 循环处理 |

### 2. Code 节点（n8n-code-javascript）

```javascript
// 模式选择
$input.all()      // Run Once for All Items（推荐）
$input.item       // Run Once for Each Item

// 返回格式（必须）
return [{json: {field: value}}];

// Webhook 数据
$json.body.field  // 不是 $json.field

// 跨迭代累积（SplitInBatches）
$getWorkflowStaticData('global').results = [];
```

### 3. 表达式语法（n8n-expression-syntax）

```
// 基本格式
{{$json.field}}

// Webhook 数据
{{$json.body.field}}

// 节点引用
{{$node["HTTP Request"].json.data}}

// Code 节点中不用 {{}}
$json.field
```

### 4. MCP 工具（n8n-mcp-tools-expert）

```javascript
// 搜索节点
search_nodes({query: "slack"})

// 获取节点详情
get_node({nodeType: "nodes-base.slack"})

// 验证配置
validate_node({nodeType: "nodes-base.slack", config: {...}, profile: "runtime"})

// 创建工作流
n8n_create_workflow({name: "...", nodes: [...], connections: {...}})

// 编辑工作流
n8n_update_partial_workflow({id: "...", operations: [...]})

// 激活工作流
n8n_update_partial_workflow({id: "...", operations: [{type: "activateWorkflow"}]})
```

**格式差异**：
- 搜索/验证：`nodes-base.slack`
- 工作流工具：`n8n-nodes-base.slack`

### 5. 验证（n8n-validation-expert）

```javascript
// 验证配置
validate_node({nodeType, config, profile: "runtime"})

// 验证配置选择
"minimal"     // 仅必填字段
"runtime"     // 推荐（默认）
"ai-friendly" // 减少误报
"strict"      // 最严格

// 错误类型
"missing_required"  // 缺少必填字段
"invalid_value"     // 值无效
"type_mismatch"     // 类型错误
"invalid_expression" // 表达式错误
```

## 常见场景速查

### 场景 1：创建 Webhook → Slack 工作流

```javascript
// 1. 搜索节点
search_nodes({query: "webhook"})
search_nodes({query: "slack"})

// 2. 获取详情
get_node({nodeType: "nodes-base.webhook"})
get_node({nodeType: "nodes-base.slack"})

// 3. 创建工作流
n8n_create_workflow({
  name: "Webhook to Slack",
  nodes: [
    {name: "Webhook", type: "n8n-nodes-base.webhook", parameters: {path: "notify", httpMethod: "POST"}},
    {name: "Slack", type: "n8n-nodes-base.slack", parameters: {resource: "message", operation: "post", channel: "#general", text: "={{$json.body.message}}"}}
  ],
  connections: {"Webhook": {"main": [[{"node": "Slack", "type": "main", "index": 0}]]}}
})

// 4. 验证
n8n_validate_workflow({id: "workflow-id"})

// 5. 激活
n8n_update_partial_workflow({id: "workflow-id", operations: [{type: "activateWorkflow"}]})
```

### 场景 2：Code 节点数据转换

```javascript
// JavaScript Code 节点配置
{
  "jsCode": "const items = $input.all();\nreturn items.map(item => ({\n  json: {\n    id: item.json.id,\n    name: item.json.name.toUpperCase(),\n    processed: true\n  }\n}));"
}
```

### 场景 3：定时数据库同步

```javascript
// 1. 创建工作流
n8n_create_workflow({
  name: "Database Sync",
  nodes: [
    {name: "Schedule", type: "n8n-nodes-base.scheduleTrigger", parameters: {"rule": {"interval": [{"field": "hours", "hoursInterval": 1}]}}},
    {name: "Source DB", type: "n8n-nodes-base.postgres", parameters: {operation: "executeQuery", query: "SELECT * FROM users WHERE updated_at > NOW() - INTERVAL '1 hour'"}},
    {name: "Target DB", type: "n8n-nodes-base.postgres", parameters: {operation: "insert", table: "users_backup"}}
  ],
  connections: {"Schedule": {"main": [[{"node": "Source DB", "type": "main", "index": 0}]]}, "Source DB": {"main": [[{"node": "Target DB", "type": "main", "index": 0}]]}}
})
```

## 常见错误速查

| 错误 | 原因 | 修复 |
|------|------|------|
| `Node not found` | nodeType 格式错误 | 搜索/验证用 `nodes-base.xxx`，工作流用 `n8n-nodes-base.xxx` |
| `Missing required field` | 缺少必填字段 | 使用 `get_node` 查看必填字段 |
| `Invalid expression` | 表达式语法错误 | 添加 `{{}}`，检查节点名拼写 |
| `Cannot read property` | 数据路径错误 | Webhook 数据在 `.body` 下 |
| `paired_item_no_info` | 缺少 pairedItem | 新项目添加 `pairedItem: {item: i}` |

## 工作流创建清单

- [ ] 确定工作流模式
- [ ] 搜索所需节点
- [ ] 获取节点配置详情
- [ ] 配置节点参数
- [ ] 验证节点配置
- [ ] 创建工作流
- [ ] 验证工作流
- [ ] 激活工作流

## 相关文档

- 详细项目结构：`docs/PROJECT_STRUCTURE.md`
- Claude Code 指南：`CLAUDE.md`
- 部署文档：`README.md`
