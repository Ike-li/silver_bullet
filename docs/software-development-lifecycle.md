# 软件开发全生命周期——后端开发视角

面向后端开发者的完整工程流程参考。从需求到运维，8 个阶段构成闭环。

## 全局视图

```
需求与规划 → 设计与架构 → 开发 → 代码评审 → 测试 → CI/CD → 部署 → 运维
  ↑                                                              |
  └───────────────── 生产反馈驱动下一轮需求 ─────────────────────┘
```

本仓库工具在闭环中的位置：

| 工具 | 覆盖阶段 |
|:-----|:---------|
| spec-kit（`/speckit.*` 命令） | 需求 → 设计 → 任务拆解 |
| silver-bullet-spec | 设计 → 开发的衔接（分析 → 计划 → 进度 → 归档） |
| systematic-debugging-lite | 开发 + 运维阶段的问题定位 |
| frontend-e2e-bootstrap | 测试阶段的前端 E2E 体系搭建 |

---

## 1. 需求与规划

**做什么**：把业务想法变成可执行的需求定义。

- 产品经理写 PRD（产品需求文档）
- 技术负责人做可行性评估
- 团队估点排期

**后端的角色**：评估技术可行性、识别数据模型需求、给出工期估算。很多后端低估这一步——如果需求阶段不参与，后面会反复返工。

**产出**：PRD、用户故事、验收标准、排期

**对应 spec-kit**：`/speckit.specify`（生成结构化需求规范）+ `/speckit.clarify`（消歧）

---

## 2. 设计与架构

**做什么**：把需求翻译成技术方案。

- 系统架构设计（单体 vs 微服务、同步 vs 异步）
- 数据模型设计（ER 图、表结构、索引策略）
- 接口契约设计（API 路径、请求/响应格式、错误码）
- 技术选型（框架、中间件、第三方服务）
- 非功能需求（性能目标、容量规划、安全要求）

**后端的角色**：这是后端最核心的阶段。方案对不对决定了后面所有工作的质量。

**产出**：技术方案文档、数据模型、API 契约、架构图

**对应 spec-kit**：`/speckit.plan`（生成 plan.md + data-model.md + contracts/ + research.md）

---

## 3. 开发

**做什么**：写代码。

典型后端开发流程：

```
拉分支 → 写测试（TDD）→ 写实现 → 本地验证 → 提交 → 发起 PR
```

### 关键实践

| 实践 | 说明 |
|:-----|:-----|
| **分支策略** | Git Flow / Trunk-Based Development，团队统一 |
| **TDD** | 核心逻辑先写失败测试再写实现 |
| **代码规范** | lint + format + type-check，CI 自动检查 |
| **小步提交** | 每个 commit 解决一个清晰问题，方便 review 和回滚 |
| **数据库迁移** | migration 文件版本化管理，不手动改表 |

### 后端特别关注

- **幂等性**：接口重试不产生副作用（特别是支付、扣库存）
- **并发控制**：乐观锁 / 分布式锁，禁止无保护的读-改-写
- **事务边界**：哪些操作必须原子，事务不能跨服务
- **错误处理**：给上游可执行的错误信息，不是裸抛 500

**对应 spec-kit**：`/speckit.tasks`（任务拆解）+ `/speckit.implement`（按任务实施）

### 实践：TDD 开发一个优惠券核销接口

```python
# 第一步：先写失败测试
# tests/test_coupon_service.py

def test_apply_coupon_deducts_from_order():
    """满减券：订单 200 元，满 150 减 30"""
    order = Order(amount=Decimal("200"))
    coupon = Coupon(type="threshold", threshold=150, discount=30)
    result = apply_coupon(order, coupon)
    assert result.final_amount == Decimal("170")

def test_coupon_cannot_exceed_order_amount():
    """折扣不能超过订单金额"""
    order = Order(amount=Decimal("20"))
    coupon = Coupon(type="fixed", discount=50)
    result = apply_coupon(order, coupon)
    assert result.final_amount == Decimal("0")  # 最低为 0，不倒贴

def test_expired_coupon_rejected():
    """过期券不能用"""
    coupon = Coupon(type="fixed", discount=10, expires_at=datetime(2024, 1, 1))
    with pytest.raises(CouponExpired):
        apply_coupon(Order(amount=Decimal("100")), coupon)

def test_coupon_already_used():
    """已核销的券不能再用"""
    coupon = Coupon(type="fixed", discount=10, used_at=datetime.now())
    with pytest.raises(CouponAlreadyUsed):
        apply_coupon(Order(amount=Decimal("100")), coupon)
```

```python
# 第二步：运行测试，确认全部失败（红）

$ pytest tests/test_coupon_service.py -v
# FAILED test_apply_coupon_deducts_from_order - NameError: name 'apply_coupon' is not defined
# FAILED test_coupon_cannot_exceed_order_amount
# FAILED test_expired_coupon_rejected
# FAILED test_coupon_already_used
```

```python
# 第三步：写最小实现让测试通过（绿）
# src/services/coupon.py

def apply_coupon(order: Order, coupon: Coupon) -> ApplyResult:
    if coupon.used_at is not None:
        raise CouponAlreadyUsed(coupon.id)
    if coupon.expires_at and coupon.expires_at < datetime.now():
        raise CouponExpired(coupon.id)

    discount = _calculate_discount(order, coupon)
    final_amount = max(order.amount - discount, Decimal("0"))
    return ApplyResult(final_amount=final_amount, discount=discount)

def _calculate_discount(order: Order, coupon: Coupon) -> Decimal:
    if coupon.type == "fixed":
        return coupon.discount
    if coupon.type == "threshold":
        if order.amount >= coupon.threshold:
            return coupon.discount
        return Decimal("0")
    raise ValueError(f"Unknown coupon type: {coupon.type}")
```

```python
# 第四步：运行测试，确认全部通过
$ pytest tests/test_coupon_service.py -v
# PASSED test_apply_coupon_deducts_from_order
# PASSED test_coupon_cannot_exceed_order_amount
# PASSED test_expired_coupon_rejected
# PASSED test_coupon_already_used
```

### 实践：数据库 migration 版本化管理（Alembic）

```python
# 用 Alembic 创建 migration，不手动改表

# 生成 migration 文件
$ alembic revision --autogenerate -m "add_coupon_table"

# alembic/versions/001_add_coupon_table.py（自动生成，review 后提交）
def upgrade():
    op.create_table(
        "coupons",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("code", sa.String(32), unique=True, nullable=False),
        sa.Column("type", sa.String(20), nullable=False),
        sa.Column("discount", sa.Numeric(10, 2), nullable=False),
        sa.Column("threshold", sa.Numeric(10, 2)),
        sa.Column("expires_at", sa.DateTime),
        sa.Column("used_at", sa.DateTime),
        sa.Column("created_at", sa.DateTime, server_default=sa.func.now()),
    )
    op.create_index("ix_coupons_code", "coupons", ["code"])

def downgrade():
    op.drop_table("coupons")

# 执行 migration
$ alembic upgrade head

# 回滚
$ alembic downgrade -1
```

---

## 4. 代码评审

**做什么**：PR / MR 提交后，团队成员审查代码。

### Review 关注点（按优先级排列）

1. **正确性** — 逻辑对不对，边界条件有没有漏
2. **安全性** — SQL 注入、权限绕过、敏感数据泄露
3. **可维护性** — 命名、结构、复杂度
4. **性能** — 是否有 N+1 查询、大表全扫、缺索引
5. **测试** — 核心路径有没有测试覆盖

### 不应该在 Review 里争论的事

- 代码风格（交给 linter）
- 框架选型（应该在设计阶段定）
- 架构方向（应该在 plan review 时定）

### 实践：一个真实的 Code Review 对话

```python
# PR: "实现优惠券核销接口"

# --- Reviewer 评论 1：安全性 ---
# > src/api/coupon.py:15
# > coupon = db.query(Coupon).filter(Coupon.id == request.coupon_id).first()
#
# 这里没有校验 coupon 是否属于当前用户。用户 A 可以传 B 的 coupon_id 来用 B 的券。
# 建议加 .filter(Coupon.user_id == current_user.id)

# --- Reviewer 评论 2：正确性 ---
# > src/services/coupon.py:28
# > coupon.used_at = datetime.now()
# > order.discount = coupon.discount
# > db.commit()
#
# 这两个写操作没有包在事务里。如果 order 更新失败，coupon 已经标记为已使用了。
# 建议用 with db.begin(): 包裹。

# --- Reviewer 评论 3：性能 ---
# > src/api/coupon.py:10
# > coupons = db.query(Coupon).filter(Coupon.user_id == user_id).all()
# > valid_coupons = [c for c in coupons if c.expires_at > datetime.now()]
#
# 先查出所有券再在 Python 里过滤。如果用户有 1000 张券，全部加载到内存。
# 把过期过滤下推到 SQL：.filter(Coupon.expires_at > datetime.now())
```

---

## 5. 测试

后端测试分层，从快到慢、从细到粗：

```
单元测试 → 集成测试 → 契约测试 → E2E 测试 → 性能测试 → 安全测试
```

| 层级 | 测什么 | 速度 | 后端关注 |
|:-----|:-------|:-----|:---------|
| **单元测试** | 单个函数/方法的逻辑 | 毫秒级 | 业务规则、计算逻辑、边界条件 |
| **集成测试** | 模块间协作 + 真实数据库/缓存 | 秒级 | 数据库读写、事务、缓存一致性 |
| **契约测试** | 接口请求/响应格式是否符合约定 | 秒级 | API 兼容性、前后端契约不破裂 |
| **E2E 测试** | 完整链路从入口到出口 | 分钟级 | 关键业务流程、多服务协作 |
| **性能测试** | 压力/负载/容量 | 分钟级 | 接口 QPS、P99 延迟、数据库瓶颈 |
| **安全测试** | 漏洞扫描、渗透测试 | 不定 | OWASP Top 10、依赖 CVE |

**经验法则**：单元测试覆盖广度，集成测试覆盖深度，E2E 只覆盖最核心的 happy path。

### 测试数据管理

- 集成测试用独立的测试数据库，每次跑测试前 reset
- 不依赖生产数据做测试（合规风险 + 数据不稳定）
- 工厂模式生成测试数据（factory），不手写 fixture JSON

---

## 6. CI/CD（持续集成 / 持续交付）

**做什么**：自动化构建、测试、部署的流水线。

### 典型后端 CI/CD 流水线

```
代码提交
  ↓
CI Pipeline（每次 PR 触发）
  ├── lint + type-check + format 检查
  ├── 单元测试
  ├── 集成测试（启动测试数据库）
  ├── 构建产物（Docker 镜像 / JAR / 二进制）
  ├── 安全扫描（依赖 CVE + 代码扫描）
  └── 镜像推送到 Registry
  ↓
CD Pipeline（合并主分支后触发）
  ├── 部署到 Staging 环境
  ├── Smoke 测试
  ├── 人工确认（或自动）
  └── 部署到 Production
```

### 关键原则

- **CI 必须快**（< 10 分钟），否则开发会跳过。慢的测试（性能测试、完整 E2E）放到 nightly 或合并后跑
- **CI 挂了必须立刻修**，不能"先合了再说"
- **构建产物不可变**：staging 验证通过的镜像原封不动部署到 production，不重新构建
- **环境一致性**：dev / staging / production 的基础设施配置尽量一致，用 IaC（Infrastructure as Code）管理

### 实践：GitHub Actions CI 配置（Python + PostgreSQL）

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync
      - run: uv run ruff check .          # lint
      - run: uv run ruff format --check .  # format
      - run: uv run mypy src/              # type-check

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: test
          POSTGRES_PASSWORD: test
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7
        ports: ["6379:6379"]

    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync

      # 单元测试（快，不依赖外部服务）
      - run: uv run pytest tests/unit/ -v --tb=short

      # 集成测试（用真实 PostgreSQL + Redis）
      - run: uv run pytest tests/integration/ -v --tb=short
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/test
          REDIS_URL: redis://localhost:6379

      # 契约测试
      - run: uv run pytest tests/contract/ -v --tb=short
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/test

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/build-push-action@v5
        with:
          push: ${{ github.ref == 'refs/heads/main' }}
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync
      - run: uv run pip-audit  # 扫描依赖 CVE
```

### 实践：Dockerfile（Python 后端）

```dockerfile
# Dockerfile
FROM python:3.12-slim AS base

# 不用 root 运行
RUN useradd --create-home appuser
WORKDIR /home/appuser

# 先装依赖（利用 Docker 层缓存）
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

# 再复制代码
COPY src/ src/
COPY alembic/ alembic/
COPY alembic.ini .

USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 7. 部署

### 部署策略

从保守到激进：

| 策略 | 原理 | 适用场景 |
|:-----|:-----|:---------|
| **停机部署** | 下线 → 部署 → 上线 | 内部工具、可接受短暂下线 |
| **滚动部署** | 逐个实例替换 | 无状态服务、Kubernetes 默认 |
| **蓝绿部署** | 两套环境切流量 | 需要快速回滚 |
| **金丝雀发布** | 先给 1-5% 流量，观察后全量 | 高风险变更、用户量大 |
| **Feature Flag** | 代码已部署但功能未开启，按条件灰度 | 长期并行开发、A/B 测试 |

### 后端部署特别关注

- **数据库迁移**：migration 必须向前兼容（先加列后删列，不能直接改列名），因为部署过程中新旧代码共存
- **配置管理**：环境变量 / 配置中心，不在代码里硬编码
- **健康检查**：readiness probe（能接流量吗）+ liveness probe（还活着吗）
- **优雅关闭**：收到终止信号后，完成处理中的请求再退出，不强杀
- **回滚方案**：每次部署前确认"怎么回滚"，不是出事后临时想

### 数据库迁移的安全模式

改表结构的安全顺序（适用于滚动部署 / 蓝绿部署）：

```
添加新列（可选、有默认值）
  ↓
部署新代码（同时读写新旧列）
  ↓
回填历史数据
  ↓
部署只读新列的代码
  ↓
删除旧列
```

每一步之间可以独立部署和回滚。禁止一次性改列名或改类型。

### 实践：数据库迁移安全模式（把 username 改名为 display_name）

```python
# 错误做法：一步到位（部署过程中旧代码读 username 会报错）
# ❌ op.alter_column("users", "username", new_column_name="display_name")

# 正确做法：分 4 次部署

# --- 部署 1：加新列 ---
# alembic/versions/042_add_display_name.py
def upgrade():
    op.add_column("users", sa.Column("display_name", sa.String(100)))

# --- 部署 2：代码同时读写两列 ---
# src/models/user.py
class User(Base):
    username = Column(String(100))       # 旧列，继续写
    display_name = Column(String(100))   # 新列，同步写

    def save(self):
        self.display_name = self.username  # 双写
        super().save()

# --- 部署 3：回填历史数据 + 代码只读新列 ---
# alembic/versions/043_backfill_display_name.py
def upgrade():
    op.execute("UPDATE users SET display_name = username WHERE display_name IS NULL")

# --- 部署 4：删除旧列 ---
# alembic/versions/044_drop_username.py
def upgrade():
    op.drop_column("users", "username")
```

### 实践：优雅关闭（FastAPI + uvicorn）

```python
# src/main.py
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动时：初始化连接池、预热缓存
    await db.connect()
    await redis.connect()
    print("App started")

    yield

    # 关闭时：等待进行中的请求完成，然后释放资源
    print("Shutting down gracefully...")
    await db.disconnect()
    await redis.disconnect()
    print("Cleanup done")

app = FastAPI(lifespan=lifespan)

# uvicorn 收到 SIGTERM 时会等待进行中的请求完成（默认等 30 秒）
# 在 K8s 中，terminationGracePeriodSeconds 要大于这个值
```

---

## 8. 运维与可观测性

代码上线不是终点，是另一段旅程的开始。

### 可观测性三支柱

| 支柱 | 回答什么问题 | 工具举例 |
|:-----|:-------------|:---------|
| **Metrics（指标）** | "系统现在怎么样？" | Prometheus + Grafana |
| **Logs（日志）** | "刚才发生了什么？" | ELK / Loki |
| **Traces（链路追踪）** | "这个请求经过了哪些服务？" | Jaeger / OpenTelemetry |

三者互补：metrics 发现异常，logs 定位细节，traces 跟踪跨服务调用链。

### 后端必须监控的指标

| 指标 | 为什么重要 |
|:-----|:-----------|
| **请求量（QPS）** | 流量异常是最早的告警信号 |
| **错误率（4xx/5xx）** | 直接影响用户体验 |
| **延迟（P50/P95/P99）** | P99 比平均值重要得多 |
| **数据库连接池** | 连接耗尽 = 全站挂 |
| **队列积压深度** | 异步任务处理是否跟得上 |
| **磁盘/内存/CPU** | 资源耗尽前预警 |

### 日志规范

- **结构化日志**（JSON），不是纯文本拼接
- **每条日志带 trace_id**，方便跨服务追踪
- **日志分级**：ERROR（需要人介入）、WARN（可能有问题）、INFO（关键业务事件）、DEBUG（调试用，生产默认关闭）
- **脱敏**：密码、token、手机号、身份证不进日志

### 实践：结构化日志 + 脱敏（Python structlog）

```python
# src/logging_config.py
import structlog
import re

def redact_sensitive(_, __, event_dict):
    """脱敏处理器：自动过滤敏感字段"""
    sensitive_keys = {"password", "token", "secret", "authorization", "cookie"}
    for key in list(event_dict.keys()):
        if key.lower() in sensitive_keys:
            event_dict[key] = "***REDACTED***"

    # 手机号脱敏
    if "phone" in event_dict:
        phone = str(event_dict["phone"])
        event_dict["phone"] = phone[:3] + "****" + phone[-4:] if len(phone) == 11 else "***"

    return event_dict

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        redact_sensitive,                              # 脱敏
        structlog.processors.JSONRenderer(),           # 输出 JSON
    ],
)

log = structlog.get_logger()

# 使用
log.info("user_login", user_id=123, phone="13800138000", token="abc123secret")
# 输出：{"event": "user_login", "user_id": 123, "phone": "138****8000",
#         "token": "***REDACTED***", "timestamp": "2025-06-01T10:00:00Z", "level": "info"}
```

### 实践：FastAPI 中间件自动记录请求日志 + trace_id

```python
# src/middleware/logging.py
import uuid
import time
import structlog
from starlette.middleware.base import BaseHTTPMiddleware

log = structlog.get_logger()

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        trace_id = request.headers.get("X-Trace-ID", str(uuid.uuid4()))
        start = time.monotonic()

        # 把 trace_id 绑定到这个请求的所有日志
        with structlog.contextvars.bound_contextvars(trace_id=trace_id):
            try:
                response = await call_next(request)
                duration_ms = (time.monotonic() - start) * 1000

                log.info("request_completed",
                    method=request.method,
                    path=request.url.path,
                    status=response.status_code,
                    duration_ms=round(duration_ms, 2),
                )
                response.headers["X-Trace-ID"] = trace_id
                return response

            except Exception as e:
                duration_ms = (time.monotonic() - start) * 1000
                log.error("request_failed",
                    method=request.method,
                    path=request.url.path,
                    error=str(e),
                    duration_ms=round(duration_ms, 2),
                )
                raise

# 输出示例：
# {"event": "request_completed", "trace_id": "a1b2c3d4", "method": "POST",
#  "path": "/api/v1/orders", "status": 201, "duration_ms": 45.23, "level": "info"}
```

### 实践：Prometheus 指标埋点（FastAPI）

```python
# src/middleware/metrics.py
from prometheus_client import Counter, Histogram, generate_latest
from starlette.responses import Response

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)

REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration",
    ["method", "path"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

class MetricsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        start = time.monotonic()
        response = await call_next(request)
        duration = time.monotonic() - start

        REQUEST_COUNT.labels(
            method=request.method,
            path=request.url.path,
            status=response.status_code,
        ).inc()

        REQUEST_DURATION.labels(
            method=request.method,
            path=request.url.path,
        ).observe(duration)

        return response

# 暴露 /metrics 端点给 Prometheus 抓取
@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")

# Prometheus 会抓取到类似这样的数据：
# http_requests_total{method="POST",path="/api/v1/orders",status="201"} 1523
# http_request_duration_seconds_bucket{method="POST",path="/api/v1/orders",le="0.1"} 1480
# http_request_duration_seconds_bucket{method="POST",path="/api/v1/orders",le="0.5"} 1520
```

### 告警与 On-Call

- **告警分级**：P0（立即响应）→ P1（1 小时内）→ P2（工作日内）→ P3（下个迭代）
- **告警原则**：每条告警都必须有对应的 action，不可执行的告警就是噪音
- **On-Call 轮转**：后端开发必须参与 on-call，写的代码自己扛。这会倒逼你写更健壮的代码
- **Runbook**：常见故障的处理手册，3 AM 被叫醒时不需要从头思考

### 事故管理

```
发现 → 响应 → 止血 → 根因分析 → 修复 → 复盘
```

- **止血优先于根因**：先恢复服务（回滚、切流量、降级），再查为什么
- **Postmortem（事后复盘）**：不追责个人，关注系统和流程怎么改进。产出 action items 并跟踪落地
- **时间线记录**：什么时候发现、什么时候响应、什么时候恢复——这些数据驱动 SLO 的制定

### SLO 与 Error Budget

| 概念 | 含义 | 举例 |
|:-----|:-----|:-----|
| **SLI**（指标） | 衡量服务质量的具体指标 | 请求成功率、P99 延迟 |
| **SLO**（目标） | SLI 的目标值 | 成功率 >= 99.9%，P99 < 500ms |
| **Error Budget**（容错预算） | 允许不达标的空间 | 99.9% SLO = 每月允许 43 分钟不可用 |

Error Budget 的价值：有预算时团队可以快速迭代发版；预算快耗尽时冻结发版、优先稳定性。它让"快速迭代"和"系统稳定"不再对立。

---

## 各阶段耗时参考

以一个中等复杂度的后端功能（如"添加优惠券系统"）为例：

| 阶段 | 典型耗时 | 说明 |
|:-----|:---------|:-----|
| 需求与规划 | 1-2 天 | 含 spec + clarify |
| 设计与架构 | 1-3 天 | 含 plan + review |
| 开发 | 3-10 天 | 取决于复杂度 |
| 代码评审 | 0.5-2 天 | 每个 PR 一轮到两轮 |
| 测试 | 1-3 天 | 含补充集成测试和修复 |
| CI/CD | 持续（自动化） | 流水线本身不占人力 |
| 部署 | 0.5-1 天 | 含 staging 验证 + 灰度 |
| 运维 | 持续 | 上线后持续观察 1-2 周 |

**总计约 2-4 周**。如果用 spec-kit 走完整流程，前两个阶段可以压缩到 1-2 天。

---

## 阶段间的交接物

每个阶段的产出是下个阶段的输入。交接物不清晰是项目延期的最大原因之一。

```
需求 ──→ PRD / spec.md / 用户故事
         ↓
设计 ──→ plan.md / data-model.md / contracts/ / 架构图
         ↓
开发 ──→ 代码 + 测试 + migration + PR
         ↓
评审 ──→ approved PR
         ↓
测试 ──→ 测试报告 / 缺陷列表
         ↓
CI/CD ─→ 构建产物（Docker 镜像 / 二进制）
         ↓
部署 ──→ 上线版本 + 回滚方案 + 灰度策略
         ↓
运维 ──→ 监控 dashboard + 告警规则 + runbook
         ↓
反馈 ──→ 事故报告 / 性能数据 / 用户反馈 → 回到需求
```
