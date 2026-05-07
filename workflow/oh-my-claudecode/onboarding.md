# 老项目首次接入 OMC

## 标准流程（4 步）

```
cd your-project
claude
```

### 第 1 步：深度初始化

```
/deepinit
```

OMC 扫描整个代码库，为每个目录生成 `AGENTS.md` 文件，形成层级文档树。这些文件告诉所有 Agent：
- 这个目录是做什么的
- 关键文件有哪些
- 测试怎么跑
- 常见代码模式是什么

**产出**：项目中每个目录下都有 `AGENTS.md`，构成完整文档树。

**耗时**：取决于项目大小，通常 1-3 分钟。

### 第 2 步：验证文档

```
/skill list      # 确认 Skills 可用
```

检查生成的 AGENTS.md 文件：

```
cat AGENTS.md                    # 根目录文档
cat apps/api/AGENTS.md           # 子目录文档（如有）
```

### 第 3 步：首次试跑

选一个简单任务验证 OMC 能正常工作：

```
# 简单任务
/autopilot "给 README 添加项目架构图"

# 或者先做需求访谈
/deep-interview "我想重构认证模块"
```

### 第 4 步：审计项目（可选但推荐）

```
/autopilot "审计这个项目是否可以部署上线，检查：API 是否完整实现（非 stub）、测试是否真实可运行、Docker/部署配置是否就绪、有无 TODO/FIXME，输出一份上线清单"
```

## 什么情况下需要重新 /deepinit

- 大规模重构后（目录结构变化）
- 新增了重要模块
- AGENTS.md 内容已过时

## 实战示例：接入一个 NestJS + Expo 项目

```bash
# 1. 进入项目
cd ~/code/todo-app
claude

# 2. 深度初始化（约 1 分钟，生成 48 个 AGENTS.md）
/deepinit
# 输出：
#   AGENTS.md (root)
#   ├── apps/AGENTS.md
#   │   ├── api/AGENTS.md
#   │   │   ├── prisma/AGENTS.md
#   │   │   └── src/AGENTS.md
#   │   └── mobile/AGENTS.md
#   ├── packages/AGENTS.md
#   └── tests/AGENTS.md

# 3. 验证
/skill list
# 应该看到 46+ 个 Skills

# 4. 首次审计（发现 3 个安全问题）
/autopilot "审计项目是否可部署上线"
# 输出：
#   API 实现完整性 ✅
#   移动端完整性 ✅
#   测试质量 ✅（182/182）
#   🔴 Swagger 生产环境暴露
#   🔴 CORS * + credentials
#   🔴 CI/生产 Node 版本不一致

# 5. 修复问题
/ralph "修复这 3 个安全问题并确保测试通过"
# 自动修复 + 验证 75/75 API 测试、60/60 移动端测试

# 6. QA 验证
/ultraqa "验证所有测试通过"
# 一轮通过：182/182 tests, 3/3 lint, 2/2 build

# 7. 开始开发新功能
/autopilot "给 Todo 添加拖拽排序功能"
```

## 注意事项

- `/deepinit` 会创建大量 AGENTS.md 文件，建议加入 `.gitignore` 或提交到仓库（团队共享）
- 如果项目已有 `CLAUDE.md`，OMC 会保留它并基于它工作
- 生成的 AGENTS.md 是只读参考，OMC Agent 用它来理解项目，不会修改业务代码
