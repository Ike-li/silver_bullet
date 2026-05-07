# 自定义 Skill 开发

## 什么是 Skill

Skill 是一个 markdown 文件，告诉 Claude "什么时候用你、怎么用你"。它不是独立程序，是指令注入。

## 创建流程

### 方式一：交互式创建

```
/skill add my-skill-name
```

OMC 会引导你填写名称、描述、触发词、参数等。

### 方式二：手动创建

```
mkdir -p ~/.claude/skills/my-skill/scripts
```

创建 `SKILL.md`：

```markdown
---
name: api-check
description: Check API health and response times. Use this when the user asks to verify API status, test endpoints, check if the backend is running, or wants to monitor API performance.
argument-hint: "[--url http://localhost:3000] [--endpoint /health]"
---

# API Health Check

Quickly verify that your API is responding correctly.

## Why This Exists
Manually curl-ing endpoints is tedious and error-prone. This skill automates health checks with structured output.

## Arguments
- `--url` — Base URL (default: from .env)
- `--endpoint` — Endpoint to check (default: /health)
- `--repeat` — Number of requests (default: 1)

## Workflow

1. Read `.env` or `.env.example` to find the API URL
2. Run health check:
   ```bash
   curl -s -o /dev/null -w "%{http_code} %{time_total}s" <url><endpoint>
   ```
3. If `--repeat > 1`, run multiple times and calculate avg/p95/p99
4. Report results in a table
```

## 实例：todo-app 的 API 冒烟 Skill

假设你经常需要检查 todo-app 的 API 是否正常：

```
mkdir -p ~/code/todo-app/.omc/skills/api-smoke/scripts
```

创建 `.omc/skills/api-smoke/SKILL.md`：

```markdown
---
name: api-smoke
description: Quick API smoke test for the todo-app. Tests auth, todos CRUD, and health endpoints in sequence. Use when the user says "check API", "API smoke", "is the backend working", or "test endpoints".
argument-hint: "[--base-url http://localhost:3000]"
---

# API Smoke Test

Run a quick sequence of API calls to verify the backend is healthy.

## Why This Matters
Before starting frontend work, you need confidence that the API is up. This catches deployment issues, database connection problems, and auth misconfigurations in seconds.

## Workflow

1. Read `.env` for `API_URL` (default: `http://localhost:3000`)
2. Run the smoke script:
   ```bash
   cd .omc/skills/api-smoke/scripts && bash smoke.sh <base-url>
   ```
3. Report pass/fail for each endpoint
```

创建 `scripts/smoke.sh`：

```bash
#!/bin/bash
BASE_URL=${1:-http://localhost:3000}
PASS=0
FAIL=0

check() {
  local name=$1 method=$2 path=$3 data=$4 auth=$5
  local auth_header=""
  [ -n "$auth" ] && auth_header="-H 'Authorization: Bearer $auth'"

  local code
  if [ "$method" = "GET" ]; then
    code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$path" -H "Authorization: Bearer $auth" 2>/dev/null)
  else
    code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE_URL$path" \
      -H "Content-Type: application/json" -H "Authorization: Bearer $auth" \
      -d "$data" 2>/dev/null)
  fi

  if [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
    echo "  PASS  $name ($code)"
    PASS=$((PASS+1))
  else
    echo "  FAIL  $name ($code)"
    FAIL=$((FAIL+1))
  fi
}

echo "=== API Smoke Test: $BASE_URL ==="
echo ""

check "Health"       GET  "/"           "" ""
check "Register"     POST "/auth/register" '{"email":"smoke@test.com","password":"Test123!"}' ""

TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"smoke@test.com","password":"Test123!"}' 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -n "$TOKEN" ]; then
  check "Login"      POST "/auth/login"  '{"email":"smoke@test.com","password":"Test123!"}' ""
  check "Me"         GET  "/auth/me"     "" "$TOKEN"
  check "List Todos" GET  "/todos"       "" "$TOKEN"
  check "Create Todo" POST "/todos"      '{"title":"smoke test"}' "$TOKEN"
else
  echo "  FAIL  Login (no token)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
```

## Skill 最佳实践

### description 要"pushy"

```
# 好 — 触发面广
description: "Quick API smoke test. Use when user says check API, test endpoints, is backend working, API smoke, 健康检查, 接口测试"

# 差 — 太被动
description: "A skill for testing APIs"
```

### SKILL.md 要短，脚本要分离

```
# 好
~/.claude/skills/api-smoke/
├── SKILL.md          # 60 行指令
└── scripts/smoke.sh  # 执行逻辑

# 差 — 200 行脚本内联在 SKILL.md
```

### 解释 WHY 而不是写死 MUST

```
# 好
"Before starting frontend work, verify the API is up. This catches deployment issues early."

# 差
"ALWAYS run this check FIRST. NEVER skip this step."
```

### Skill 的作用域

| 位置 | 作用域 | 适用场景 |
|------|--------|---------|
| `~/.claude/skills/my-skill/` | 用户级（所有项目） | 通用工具 |
| `项目/.omc/skills/my-skill/` | 项目级（仅当前项目） | 项目特定逻辑 |

## 管理命令

```
/skill list              # 查看所有 Skill
/skill search api        # 搜索
/skill info api-smoke    # 详情
/skill edit api-smoke    # 编辑
/skill remove api-smoke  # 删除
/skillify                # 从当前会话提取 Skill
```
