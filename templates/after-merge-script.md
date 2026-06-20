# After-merge 脚本模板

用于 PR 合并后自动继续的低风险动作。脚本必须幂等、可审计、可重复运行，不负责合并 PR。

## 模板

```bash
#!/usr/bin/env bash
set -euo pipefail

PR_NUMBER="${1:?usage: after-merge.sh PR_NUMBER}"
LOCK_DIR=".agent-runbook/after-merge-pr-${PR_NUMBER}.lock"
LOG_DIR=".agent-runbook/logs"
LOG_FILE="${LOG_DIR}/after-merge-pr-${PR_NUMBER}.log"

mkdir -p "$LOG_DIR"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  printf 'after-merge already running or completed: pr=%s\n' "$PR_NUMBER" | tee -a "$LOG_FILE"
  exit 0
fi

cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

printf 'after-merge start: pr=%s\n' "$PR_NUMBER" | tee -a "$LOG_FILE"

# 只放幂等、低风险、可审计动作，例如刷新本地索引、生成报告、发送通知。
# command --safe-option | tee -a "$LOG_FILE"

printf 'after-merge done: pr=%s\n' "$PR_NUMBER" | tee -a "$LOG_FILE"
```

## 幂等锁

- 使用 `mkdir` 创建锁目录，原子判断是否已有任务执行。
- 锁路径应包含 PR 编号或 head SHA，避免不同 PR 互相阻塞。
- 如动作完成后需要永久防重复，可写入状态文件；不要只依赖临时进程锁。

## 允许动作

- 生成或刷新报告、索引、缓存。
- 发送通知或写入审计日志。
- 触发只读验证、健康检查或状态同步。
- 更新明确允许自动更新的非生产辅助资源。

## 禁止动作

- 自动 merge、auto-merge 或推进默认分支。
- 生产发布、回滚、流量切换。
- 删除分支、删除数据、销毁资源或清理不可恢复文件。
- 修改权限、密钥、环境变量、保护规则。
- 执行由未验证输入拼接出的 shell 命令。

## 与 watcher 配合

`scripts/watch-pr.sh --after-merge` 使用 `bash -lc "$command"` 执行命令字符串。只传入可信、审查过的命令；如果命令需要参数，优先调用固定脚本并传入受控参数：

```bash
bash scripts/watch-pr.sh --repo OWNER/REPO --pr 123 --mode merged --after-merge 'bash scripts/after-merge.sh 123'
```
