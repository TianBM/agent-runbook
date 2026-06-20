---
id: pr-watch-and-continue
title: PR 监听/合并后自动继续
triggers:
  - PR 监听
  - 合并后继续
  - watch checks
  - after merge
owner_skills:
  - worktree-isolation
risk_level: high
---

# PR 监听/合并后自动继续

用于读取或监听 PR 状态，并在 PR 合并后触发受控的后续动作。默认不自动 merge；自动继续只应执行幂等、可审计、低风险动作。生产发布、破坏性清理、权限变更必须另设显式 gate。

## 何时使用

- 需要单次读取 PR 状态、checks 或 merged 状态。
- 需要本地临时 watch PR checks 或合并状态，适合人工看守。
- 需要在 GitHub Actions 或 webhook 收到 PR merged 事件后自动继续低风险后续步骤。

## 不适用

- 需要自动合并 PR：本 runbook 和脚本都不执行 merge。
- 需要生产发布、删除资源、清理远端分支、修改权限或变更密钥。
- 后续动作不可重入、不可审计或失败后无法安全重试。

## 输入证据

- GitHub 仓库：`OWNER/REPO`。
- PR 编号：`NUMBER`。
- 目标模式：`snapshot`、`watch` 或 `event`。
- 需要等待的条件：checks 完成，或 PR `mergedAt` 非空。
- 自动继续命令的风险边界、幂等锁、日志位置和停止条件。

## 执行流程

1. 确认本次只读取或监听 PR 状态，不执行 merge 或 auto-merge。
2. 选择模式：
   - `snapshot`：单次读取 PR 状态，不轮询，适合交付前取证。
   - `watch`：本地临时 loop/watch，适合人工看守，必须设置 timeout。
   - `event`：GitHub Actions/webhook 事件驱动，推荐用于 PR 合并后自动继续。
3. `snapshot` 示例：
   ```bash
   gh pr view 123 --repo OWNER/REPO --json number,state,mergedAt,mergeStateStatus,statusCheckRollup
   ```
4. `watch` 等待 checks 示例：
   ```bash
   bash scripts/watch-pr.sh --repo OWNER/REPO --pr 123 --mode checks --interval 30 --timeout 1800
   ```
5. `watch` 等待合并并执行低风险命令示例：
   ```bash
   bash scripts/watch-pr.sh --repo OWNER/REPO --pr 123 --mode merged --after-merge 'bash scripts/after-merge.sh 123' --timeout 1800
   ```
6. `event` 模式在 GitHub Actions 或 webhook 中用 merged 事件触发，例如仅在 `pull_request.closed` 且 `pull_request.merged == true` 时运行 after-merge 脚本。
7. after-merge 命令通过 `bash -lc "$command"` 执行；只传入可信、审查过的命令字符串，不拼接未验证的用户输入。
8. 自动继续动作必须记录日志；重复触发时应通过锁文件、状态文件或外部记录跳过已完成步骤。

## 必须调用的 skill

- `worktree-isolation`：任何合并、清理或分支操作都必须遵守明确授权与隔离规则。

如任务升级为创建、更新、合并或清理 PR，请转用 Git PR 生命周期 runbook；本 runbook 不替代合并授权 gate。

## 验证命令

```bash
bash scripts/validate-runbooks.sh
bash scripts/watch-pr.sh --help
```

如要实际验证 PR 状态读取，替换仓库和 PR 编号：

```bash
bash scripts/watch-pr.sh --repo OWNER/REPO --pr 123 --mode checks --timeout 60 --interval 10
```

## 常见失败

- 把 watcher 当作 merge bot，绕过用户对具体 PR 和 head SHA 的合并授权。
- 本地 watch 未设置 timeout，形成无界循环。
- after-merge 命令不可幂等，重复事件导致重复发布或重复删除。
- 在命令字符串中拼接未验证输入，扩大 `bash -lc` 风险。
- checks 仍在 pending/running 时提前继续。
- GitHub token 缺少读取 PR 或 checks 的权限。

## 停止条件

- PR checks 出现 `failure`、`cancelled`、`timed_out`、`action_required` 或 `startup_failure`。
- 到达 timeout 仍未满足条件。
- after-merge 动作涉及生产发布、破坏性清理、权限变更、密钥变更或不可逆操作。
- 缺少 `--repo`、`--pr`、`--mode`，或 `gh pr view` 无法读取 PR。
- 自动继续命令无法证明幂等、可审计、低风险。

## 可复用 Prompt

```text
请按 PR 监听/合并后自动继续 runbook 执行：先确认不会自动 merge，再选择 snapshot、watch 或 event 模式；读取 OWNER/REPO 与 PR 编号；watch 必须设置 timeout；合并后自动继续只运行幂等、可审计、低风险动作；生产发布、破坏性清理、权限变更必须停止并要求显式 gate。完成后给出命令、结果和停止条件判断。
```
