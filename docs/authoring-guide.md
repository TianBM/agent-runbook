# 作者指南

## 写作原则

- 中文为主，命令、字段名和状态值保留英文。
- 每篇 runbook 聚焦一个任务，不写成百科。
- 不复制 skill 正文，只引用 skill 名称、适用边界和调用原因。
- 所有建议都要落到可执行步骤、验证命令或停止条件。
- runbook 通过远程索引按需发现，不要求相关 skill 逐条硬编码本文 URL；新增 runbook 时把触发词和 owner skill 写清楚，让 agent 能从索引匹配到它。

## 必填 frontmatter

```yaml
---
id: example-runbook
title: 示例 Runbook
triggers:
  - 示例触发词
owner_skills:
  - example-skill
risk_level: low
---
```

字段要求见 [runbook schema](../schemas/runbook.schema.json)。

## 必填章节

每篇 runbook 必须包含以下二级标题：

- 何时使用
- 不适用
- 输入证据
- 执行流程
- 必须调用的 skill
- 验证命令
- 常见失败
- 停止条件
- 可复用 Prompt

## 链接规则

- 相对链接必须指向仓库内存在的文件。
- 外部链接可以使用 `https://`。
- 不使用本机绝对路径作为文档链接。

## 本地校验

```bash
bash scripts/validate-runbooks.sh
```

如果输出 `ERROR`，先修复阻断项，再考虑内容润色。成功输出 `OK`。
