# systematic-debugging-lite

面向实施阶段问题排查的轻量技能：用于 bug、测试失败、异常行为、构建失败、集成问题与接入后异常的系统化定位。

## 这个 skill 是做什么的

- 把“先修复”改为“先定位根因，再修复”
- 给出可执行的调试流程：复现、采证、假设、验证、回归
- 降低猜测式修复、重复返工和连环回归

## 什么时候该用

- 你有明确故障，但根因不清楚
- 你需要解释“为什么会失败”，而不是只想试一个补丁
- 你已经修过几次但问题反复出现
- 你怀疑问题跨组件边界（例如 API → service → DB，或 build → runtime）

## 与 `silver-bullet-spec` 的分工

- **`silver-bullet-spec`**：复杂任务总控（分析、规划、进度、归档）。
- **`systematic-debugging-lite`**：执行阶段调试辅助（定位与验证）。

推荐协作方式：

1. 按 `silver-bullet-spec` 执行任务
2. 过程中出现异常时，切换 `systematic-debugging-lite` 排障
3. 若排障发现架构/方案层问题，回流 `silver-bullet-spec` 更新分析与计划

## 它不会做什么

- 不做完整项目规划或归档工作流
- 不依赖其他 superpowers skill 才能工作
- 不要求 subagent/reviewer/worktree 机制
- 不提供平台绑定安装方式或全局路径约束
- 不在根因未明确时默认直接改代码

## 推荐输出格式（每轮调试）

- 现象
- 已知证据
- 当前假设
- 验证动作
- 验证结果
- 下一步

## 为什么适合复杂任务执行阶段

- 轻量：不引入重流程
- 可执行：每一步有明确产出
- 可追溯：结论来自证据链而非直觉
- 可升级：连续失败时能及时升级到架构/计划层处理

## 相关文件

- 主规则：`SKILL.md`
- 完成前自检清单：`references/root-cause-checklist.md`
- 调试记录模板：`references/debug-log-template.md`
