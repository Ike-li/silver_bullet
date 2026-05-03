# 后端开发者的 QA 能力建设指南

写给会写 pytest 但不知道怎么"像 QA 一样思考"的后端开发者。

---

## 开发和 QA 的思维差异

这是最根本的区别，所有具体技能都建立在这个认知上：

| | 开发思维 | QA 思维 |
|:--|:---------|:--------|
| 目标 | 证明代码能工作 | 证明代码会在哪里失败 |
| 测试用例 | 从实现出发：我写了什么逻辑就测什么 | 从需求和用户出发：用户会怎么用、会怎么滥用 |
| Happy path | 重点测 | 只是起点，重点在异常路径 |
| 边界 | 想到了就测 | 系统性地枚举 |
| 环境 | 本地跑通就行 | 在接近生产的环境里跑通才算 |
| 完成标准 | 功能实现了 | 功能实现了 + 已知风险都被验证了 |

**转变的关键**：从"我的代码对不对"到"这个系统在什么情况下会坏"。

---

## 测试金字塔——后端视角

```
            ╱╲
           ╱  ╲         E2E / 冒烟测试（少、慢、贵）
          ╱────╲         验证核心业务链路端到端
         ╱      ╲
        ╱────────╲       集成测试（适量）
       ╱          ╲      验证模块间协作 + 真实中间件
      ╱────────────╲
     ╱              ╲    契约测试（按接口数量）
    ╱────────────────╲   验证 API 请求/响应格式不破裂
   ╱                  ╲
  ╱────────────────────╲  单元测试（大量、快）
 ╱                      ╲ 验证单个函数/方法的逻辑
╱────────────────────────╲
```

### 每层测什么、怎么写

#### 单元测试

**测什么**：纯业务逻辑、计算、校验、状态转换。

```python
# 好的单元测试：测业务规则
def test_coupon_cannot_exceed_order_amount():
    order = Order(amount=100)
    coupon = Coupon(type="fixed", value=150)
    result = apply_coupon(order, coupon)
    assert result.discount == 100  # 最多减到 0，不能倒贴

# 差的单元测试：测框架行为
def test_model_can_save():
    user = User(name="test")
    user.save()
    assert User.objects.count() == 1  # 这是在测 ORM，不是测你的逻辑
```

**原则**：
- 不 mock 数据库来测业务逻辑——把业务逻辑从数据库操作中拆出来
- 一个测试只验证一个行为
- 测试名字说清楚"在什么条件下期望什么结果"

#### 集成测试

**测什么**：模块间协作、数据库读写、缓存一致性、外部服务对接。

```python
# 测真实数据库交互
@pytest.mark.integration
def test_transfer_money_is_atomic(db_session):
    account_a = create_account(balance=1000)
    account_b = create_account(balance=0)

    transfer(from_=account_a, to=account_b, amount=500)

    assert get_balance(account_a.id) == 500
    assert get_balance(account_b.id) == 500

# 测异常情况下的数据一致性
@pytest.mark.integration
def test_transfer_rolls_back_on_insufficient_funds(db_session):
    account_a = create_account(balance=100)
    account_b = create_account(balance=0)

    with pytest.raises(InsufficientFunds):
        transfer(from_=account_a, to=account_b, amount=500)

    # 关键：两个账户都没变
    assert get_balance(account_a.id) == 100
    assert get_balance(account_b.id) == 0
```

**原则**：
- 用真实数据库，不 mock（用 testcontainers 或 CI 里的服务容器）
- 每个测试用独立的事务或数据，测试间不互相依赖
- 重点测"失败路径下数据是否一致"

#### 契约测试

**测什么**：API 的请求/响应格式是否符合约定，前后端之间的契约不被意外打破。

```python
# 测 API 响应格式不变
def test_get_user_response_schema(client):
    resp = client.get("/api/v1/users/1")
    assert resp.status_code == 200

    data = resp.json()
    # 验证字段存在且类型正确
    assert isinstance(data["id"], int)
    assert isinstance(data["email"], str)
    assert isinstance(data["created_at"], str)
    # 验证不会意外暴露内部字段
    assert "password_hash" not in data
    assert "internal_flags" not in data

# 测错误响应格式统一
def test_error_response_format(client):
    resp = client.get("/api/v1/users/999999")
    assert resp.status_code == 404

    data = resp.json()
    assert "error" in data
    assert "message" in data
    # 不暴露堆栈
    assert "traceback" not in data
```

**原则**：
- 新增字段不应该破坏契约（向后兼容）
- 删除或重命名字段必须有版本管理
- 错误响应格式全局统一

#### E2E / 冒烟测试

**测什么**：核心业务流程端到端能跑通。

```python
# 测完整业务链路
@pytest.mark.e2e
def test_user_registration_to_first_order():
    # 注册
    user = api.post("/register", {"email": "test@example.com", "password": "..."})
    assert user.status_code == 201

    # 登录拿 token
    token = api.post("/login", {"email": "test@example.com", "password": "..."})
    assert token.status_code == 200

    # 创建订单
    order = api.post("/orders", {"product_id": 1, "quantity": 1},
                     headers={"Authorization": f"Bearer {token.json()['token']}"})
    assert order.status_code == 201

    # 验证订单状态
    order_detail = api.get(f"/orders/{order.json()['id']}")
    assert order_detail.json()["status"] == "pending"
```

**原则**：
- 只覆盖最核心的 3-5 条链路，不追求全面
- 在接近生产的环境里跑（staging），不是本地
- E2E 失败了优先看是环境问题还是代码问题

---

## QA 的核心技能：测试设计

写测试容易，设计测试用例难。好的 QA 能系统性地找到别人想不到的场景。

### 等价类划分

把输入分成"应该产生相同结果的组"，每组测一个代表：

```
用户年龄输入框（要求 18-65）：

有效等价类：
  - 18-65 之间的值 → 取 30 作为代表

无效等价类：
  - < 18 → 取 15
  - > 65 → 取 70
  - 负数 → 取 -1
  - 非数字 → 取 "abc"
  - 空值 → 取 None
  - 超大数 → 取 999999999
```

### 边界值分析

bug 最常出现在边界上：

```
同一个年龄输入框，关键边界：

  17 → 刚好不够
  18 → 刚好够（下边界）
  19 → 安全值
  64 → 安全值
  65 → 刚好够（上边界）
  66 → 刚好超出
   0 → 零
  -1 → 负边界
```

### 状态转换测试

对有生命周期的实体，画出状态机，测每条转换路径（包括非法转换）：

```
订单状态机：

  pending ──→ paid ──→ shipped ──→ delivered
     │          │         │
     ↓          ↓         ↓
  cancelled  refunded   returned

必须测试的非法转换：
  - cancelled → paid（已取消不能付款）
  - delivered → cancelled（已签收不能取消）
  - pending → shipped（未付款不能发货）
  - refunded → shipped（已退款不能发货）
```

```python
def test_cancelled_order_cannot_be_paid():
    order = create_order(status="cancelled")
    with pytest.raises(InvalidStateTransition):
        order.pay()
    assert order.status == "cancelled"
```

### 数据组合（Pairwise Testing）

当输入参数多、每个参数有多种取值时，全组合测不完。用 pairwise 策略覆盖所有两两组合：

```
支付场景：
  - 支付方式：微信、支付宝、银行卡
  - 订单类型：普通、预售、团购
  - 优惠券：无、满减、折扣
  - 用户类型：新用户、老用户、VIP

全组合 = 3 × 3 × 3 × 3 = 81 个
Pairwise ≈ 9-12 个（覆盖所有两两组合）
```

Python 工具：`allpairspy` 库可以自动生成 pairwise 用例。

---

## 后端 QA 的重点场景

以下是后端最容易出 bug 的地方，QA 必须重点覆盖：

### 并发与竞态

```python
# 测两个人同时抢最后一件库存
def test_concurrent_stock_deduction():
    product = create_product(stock=1)

    results = run_concurrent(
        lambda: buy_product(product.id, user_id=1),
        lambda: buy_product(product.id, user_id=2),
    )

    success_count = sum(1 for r in results if r.success)
    assert success_count == 1  # 只有一个人能买到
    assert get_stock(product.id) == 0  # 库存不能变成负数
```

### 幂等性

```python
# 测同一个请求发两次不会产生副作用
def test_payment_is_idempotent():
    order = create_order(amount=100)
    idempotency_key = "unique-key-123"

    resp1 = api.post("/pay", {"order_id": order.id},
                     headers={"Idempotency-Key": idempotency_key})
    resp2 = api.post("/pay", {"order_id": order.id},
                     headers={"Idempotency-Key": idempotency_key})

    assert resp1.status_code == 200
    assert resp2.status_code == 200
    assert resp1.json()["transaction_id"] == resp2.json()["transaction_id"]
    # 只扣了一次钱
    assert get_balance(order.user_id) == original_balance - 100
```

### 数据边界

```python
# 测超长输入
def test_username_max_length():
    resp = api.post("/register", {"username": "a" * 10000, "password": "valid"})
    assert resp.status_code == 422  # 应该被校验拦住，不是 500

# 测特殊字符
def test_username_with_special_chars():
    for username in ["'; DROP TABLE users;--", "<script>alert(1)</script>",
                     "user\x00name", "user\nname", "  ", ""]:
        resp = api.post("/register", {"username": username, "password": "valid"})
        assert resp.status_code in (400, 422)

# 测 Unicode
def test_unicode_input():
    resp = api.post("/register", {"username": "用户😀", "password": "valid"})
    # 根据业务决策：要么接受要么明确拒绝，不能 500
    assert resp.status_code in (201, 422)
```

### 时间相关

```python
# 测跨天边界
@freeze_time("2025-12-31 23:59:59")
def test_coupon_expires_at_midnight():
    coupon = create_coupon(expires_at="2025-12-31")
    assert coupon.is_valid()  # 23:59:59 还有效

@freeze_time("2026-01-01 00:00:00")
def test_coupon_expired_after_midnight():
    coupon = create_coupon(expires_at="2025-12-31")
    assert not coupon.is_valid()  # 00:00:00 过期

# 测时区
def test_user_sees_correct_time_in_their_timezone():
    event = create_event(time="2025-06-01T10:00:00Z")
    # 东八区用户看到 18:00
    assert format_for_user(event.time, tz="Asia/Shanghai") == "2025-06-01 18:00"
```

### 权限

```python
# 测越权访问
def test_user_cannot_access_other_users_data():
    user_a = create_user()
    user_b = create_user()
    order = create_order(user_id=user_a.id)

    resp = api.get(f"/orders/{order.id}",
                   headers=auth_header(user_b))
    assert resp.status_code == 403  # 不是 404，不是 200

# 测权限提升
def test_normal_user_cannot_call_admin_api():
    user = create_user(role="user")
    resp = api.delete("/admin/users/1",
                      headers=auth_header(user))
    assert resp.status_code == 403
```

### 外部依赖故障

```python
# 测第三方服务超时
def test_payment_gateway_timeout(mock_payment):
    mock_payment.set_timeout(30)  # 模拟支付网关超时
    resp = api.post("/pay", {"order_id": 1})

    # 应该优雅降级，不是挂起或 500
    assert resp.status_code == 503
    assert "稍后重试" in resp.json()["message"]
    # 关键：订单状态不应该变成"已支付"
    assert get_order(1).status == "pending"

# 测第三方返回异常数据
def test_payment_gateway_returns_garbage(mock_payment):
    mock_payment.set_response(status=200, body="not json")
    resp = api.post("/pay", {"order_id": 1})
    assert resp.status_code == 502
    assert get_order(1).status == "pending"
```

---

## 非功能测试

功能测对了不代表能上生产。

### 性能测试

| 类型 | 目的 | 工具 |
|:-----|:-----|:-----|
| **基准测试** | 单接口在正常负载下的延迟和吞吐 | locust / k6 / wrk |
| **负载测试** | 逐步加压到预期峰值，观察系统表现 | locust / k6 |
| **压力测试** | 超过极限后系统是否优雅降级而不是崩溃 | locust / k6 |
| **浸泡测试** | 长时间运行，检查内存泄漏、连接池耗尽 | locust + 监控 |

```python
# locust 示例
from locust import HttpUser, task, between

class OrderUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def list_orders(self):
        self.client.get("/api/v1/orders")

    @task(1)
    def create_order(self):
        self.client.post("/api/v1/orders", json={"product_id": 1})
```

**后端 QA 必须知道的性能指标**：

- **QPS**：每秒处理多少请求
- **P50/P95/P99 延迟**：50%/95%/99% 的请求在多少毫秒内完成。P99 比平均值重要
- **错误率**：加压过程中 5xx 的比例
- **资源占用**：CPU、内存、数据库连接数、队列深度

### 安全测试

后端 QA 必须会的最低安全检查：

| 检查项 | 怎么测 |
|:-------|:-------|
| **SQL 注入** | 在所有输入字段传 `' OR 1=1 --`，不应该返回非预期数据 |
| **XSS（存储型）** | 提交 `<script>alert(1)</script>` 到文本字段，返回时应该被转义 |
| **越权访问** | 用 A 的 token 访问 B 的资源 |
| **敏感数据泄露** | 检查 API 响应里有没有 password_hash、internal_id、debug 信息 |
| **速率限制** | 登录接口 1 秒打 100 次，应该被限流而不是全部处理 |
| **依赖漏洞** | `pip-audit` 或 `safety check` 扫描已知 CVE |

---

## 测试基础设施

会写测试用例只是一半，另一半是让测试可靠地自动运行。

### 测试环境管理

```
本地开发 → 用 Docker Compose 跑依赖（DB、Redis、MQ）
CI 环境  → 用 testcontainers 或 CI service containers
Staging  → 接近生产的独立环境，跑 E2E 和冒烟测试
```

```yaml
# docker-compose.test.yml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: test
      POSTGRES_PASSWORD: test
  redis:
    image: redis:7
```

### 测试数据管理

| 方式 | 适用 | 不适用 |
|:-----|:-----|:-------|
| 工厂模式（factory_boy） | 集成测试、需要灵活构造数据 | 性能测试 |
| Fixture 文件 | 稳定不变的参考数据 | 频繁变化的数据结构 |
| 数据库快照 | 性能测试、大数据量场景 | 数据结构频繁变化时 |
| 生产数据脱敏 | 真实数据分布的测试 | 有合规风险时 |

```python
# factory_boy 示例
import factory

class UserFactory(factory.Factory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f"user_{n}")
    email = factory.LazyAttribute(lambda obj: f"{obj.username}@test.com")
    role = "user"

class AdminFactory(UserFactory):
    role = "admin"

# 使用
user = UserFactory()
admin = AdminFactory()
vip = UserFactory(role="vip", username="special_user")
```

### 测试可靠性

测试最大的敌人是 flaky test（时灵时不灵的测试）：

| 常见原因 | 解决方案 |
|:---------|:---------|
| 依赖执行顺序 | 每个测试独立 setup/teardown |
| 依赖当前时间 | 用 freezegun 冻结时间 |
| 依赖网络 | 外部服务用 mock/stub，不真调 |
| 数据库状态残留 | 每个测试用事务回滚或独立数据库 |
| 异步操作未等待 | 用显式等待而不是 sleep |
| 端口冲突 | 用随机端口或容器隔离 |

**规则**：一个 flaky test 比没有测试更糟糕——它会让团队习惯性忽略失败。发现 flaky test 要么立刻修，要么立刻删，不要留着。

---

## QA 的工作节奏

### 在开发周期中的介入时机

```
需求阶段 ──→ QA 参与需求评审，提出"这个场景怎么测""这个边界没定义"
              （最高 ROI 的介入点——这时候发现问题修复成本最低）

设计阶段 ──→ QA 审查 API 契约，提出"错误响应格式要统一""这个接口缺分页"
              （发现设计缺陷比发现代码 bug 便宜 10 倍）

开发阶段 ──→ 开发写单元测试和集成测试，QA 补充测试用例设计
              （QA 不需要写所有测试，但需要设计测试场景）

提测阶段 ──→ QA 跑集成测试 + E2E + 探索性测试
              （自动化能覆盖的让自动化跑，人去做探索性测试）

上线阶段 ──→ QA 跑冒烟测试确认核心链路
              （上线后 QA 盯监控 30 分钟）
```

### 探索性测试

自动化测试验证"已知的场景"，探索性测试发现"未想到的场景"。

方法：给自己一个限时任务（30 分钟），带着一个主题去"搞破坏"：

- "我要在 30 分钟内试遍所有能让支付失败的方式"
- "我要在 30 分钟内看看权限系统有没有越权的口子"
- "我要在 30 分钟内用极端数据（超长、特殊字符、空值）测试所有输入"

记录你的路径和发现，不管有没有找到 bug——"没找到"也是有价值的信息。

---

## 从开发到 QA 的技能路线图

### 第一阶段：补齐基础（1-2 个月）

- [ ] 掌握测试设计方法（等价类、边界值、状态转换）
- [ ] 会用 pytest 的 fixture、parametrize、marker 组织测试
- [ ] 会用 factory_boy 构造测试数据
- [ ] 会用 testcontainers 搭建测试环境
- [ ] 能区分单元测试、集成测试、E2E 测试的边界

### 第二阶段：建立体系（2-4 个月）

- [ ] 能为一个新功能设计完整的测试用例集（不是只测 happy path）
- [ ] 能搭建 CI 中的测试流水线（lint → 单元 → 集成 → 契约）
- [ ] 会用 locust 做基本的性能测试
- [ ] 掌握基本的安全测试（注入、越权、泄露）
- [ ] 能识别和修复 flaky test

### 第三阶段：影响团队（4-6 个月）

- [ ] 在需求评审和设计评审中能提出有价值的测试视角
- [ ] 能定义团队的测试规范（什么必须测、什么可以不测、测到什么程度）
- [ ] 能做探索性测试并形成可复用的检查清单
- [ ] 能判断"这个功能的测试够不够"而不是"测试多不多"
- [ ] 能从线上故障反推测试覆盖的盲区

---

## 推荐资源

| 资源 | 类型 | 价值 |
|:-----|:-----|:-----|
| 《Google 软件测试之道》 | 书 | 理解大规模软件的测试体系和角色分工 |
| 《探索式软件测试》(James Whittaker) | 书 | 学会像 QA 一样思考，而不只是写 assert |
| pytest 官方文档 | 文档 | Python 测试的标准工具链 |
| locust.io 文档 | 文档 | Python 性能测试入门 |
| OWASP Testing Guide | 文档 | 安全测试的系统化方法 |
| testcontainers-python | 库 | 用 Docker 管理测试依赖 |
| factory_boy | 库 | 测试数据工厂 |
| hypothesis | 库 | 基于属性的测试（自动生成边界输入） |
| freezegun | 库 | 冻结时间，解决时间相关的 flaky test |
