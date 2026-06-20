---
id: example-runbook
title: 示例 Runbook
triggers:
  - 示例触发词
owner_skills:
  - example-skill
risk_level: low
---

# 示例 Runbook

一句话说明本 runbook 的任务边界。

## 何时使用

- 适用场景。

## 不适用

- 不适用场景。

## 输入证据

- 必须先收集的事实、路径、命令输出或用户授权。

## 执行流程

1. 第一步。
2. 第二步。

## 必须调用的 skill

- `example-skill`：说明为什么必须调用。

## 验证命令

```bash
bash scripts/validate-runbooks.sh
```

## 常见失败

- 常见错误。

## 停止条件

- 需要停止并询问用户的条件。

## 可复用 Prompt

```text
请按本 runbook 执行：先收集输入证据，再调用必要 skill，完成后运行验证命令；遇到停止条件时不要继续。
```
