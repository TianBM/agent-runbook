---
id: git-pr-lifecycle
title: Git PR 生命周期
triggers:
  - 提交代码
  - 创建 PR
  - 合并授权
  - 清理 worktree
owner_skills:
  - worktree-isolation
  - git-commit
risk_level: high
---

# Git PR 生命周期

用于把一次代码修改从隔离开发推进到待审 PR，并在获得明确合并授权后清理现场。相关背景见 [架构说明](../docs/architecture.md)。

## 何时使用

- 需要修改代码、提交 commit、推送分支或创建 PR。
- 需要检查 PR checks，并向用户汇报是否可合并。
- 用户在 PR 已创建后，对具体 PR 和 head SHA 明确说“合并”。

## 不适用

- 只读分析、文档阅读或不落盘的建议。
- 用户只要求本地改动，不要求 commit、push 或 PR。
- 未拿到明确合并授权时，不执行 merge 或 auto-merge。

## 输入证据

- 当前仓库路径、当前分支、目标分支。
- `git status`、`git diff`、最近提交记录。
- PR URL、head SHA、CI/checks 状态。
- 用户对具体 PR 和 head SHA 的合并授权。

## 执行流程

1. 先确认 worktree 隔离：`GIT_DIR != GIT_COMMON` 且当前分支不是 main 或默认分支。
2. 如不满足，先创建功能分支 worktree，再进入该目录开发。
3. 修改完成后运行项目相关验证，记录命令与结果。
4. 提交前检查 `git status`、`git diff`、`git log --oneline -10`，只 stage 预期文件。
5. 使用仓库约定写 commit message，提交后再次检查状态。
6. 推送当前功能分支，创建或更新 PR，不开启 auto-merge。
7. 查看 checks；若失败，修复后重新提交并更新 PR。
8. 仅在用户对具体 PR 和 head SHA 明确授权后执行合并。
9. 合并完成且可验证后，清理本地 worktree、本地分支和远端源分支。

## 必须调用的 skill

- `worktree-isolation`：任何代码修改前必须确认隔离，合并后按其规则清理。
- `git-commit`：需要创建 commit 时使用，遵守本地中文提交模板。

## 验证命令

```bash
git status --short
git diff --stat
git log --oneline -10
```

如仓库有测试或 lint，补充运行对应命令，并把输出摘要写入 PR 描述或交付回复。

## 常见失败

- 在 main 或主检出直接开发。
- stage 了无关文件、密钥或生成物。
- PR checks 失败仍声称可以合并。
- 用户只说“看起来可以”但未对 PR 和 head SHA 明确授权。
- squash 合并后马上删分支，却没有平台合并证据。

## 停止条件

- 发现未隔离或当前分支是 main：停止修改，先建 worktree。
- checks 失败且无法在当前范围内修复：停止并汇报失败证据。
- 合并授权不明确：停止在待审 PR 状态。
- 合并后清理命令提示未合并或工作树不干净：停止强删。

## 可复用 Prompt

```text
请按 Git PR 生命周期处理本次改动：先确认 worktree 隔离，完成修改和验证；提交前检查 status/diff/log；只提交预期文件；推送并创建 PR；查看 checks；没有我对具体 PR 和 head SHA 的明确授权前不要合并；合并后再按规则清理 worktree 和分支。
```
