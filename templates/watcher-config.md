# Watcher 配置模板

用于描述 PR 状态读取、临时 watch 或事件驱动自动继续的配置字段。配置本身不代表合并授权。

## 字段

```yaml
repo: OWNER/REPO
pr: 123
mode: snapshot # snapshot | watch | event
wait_for: checks # checks | merged
interval_seconds: 30
timeout_seconds: 1800
after_merge_command: "bash scripts/after-merge.sh 123"
audit_log: ".agent-runbook/logs/after-merge-pr-123.log"
requires_explicit_gate:
  - production_deploy
  - destructive_cleanup
  - permission_change
  - secret_change
```

## 模式

### snapshot

单次读取 PR 状态，不轮询，适合取证或交付汇报。

```bash
gh pr view 123 --repo OWNER/REPO --json number,state,mergedAt,mergeStateStatus,statusCheckRollup
```

### watch

本地临时 loop/watch，适合人工看守。必须设置 timeout，避免无界循环。

```bash
bash scripts/watch-pr.sh --repo OWNER/REPO --pr 123 --mode checks --interval 30 --timeout 1800
```

### event

GitHub Actions 或 webhook 事件驱动，推荐用于 PR 合并后自动继续。触发条件应限定为 PR closed 且 merged 为 true；后续动作必须幂等、可审计、低风险。

```yaml
on:
  pull_request:
    types: [closed]

jobs:
  after-merge:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/after-merge.sh "${{ github.event.pull_request.number }}"
```

## 风险边界

- 默认不自动 merge。
- 自动继续只执行幂等、可审计、低风险动作。
- 生产发布、破坏性清理、权限变更、密钥变更需要显式 gate。
- `after_merge_command` 不拼接未验证输入；复杂逻辑放入受审脚本。
