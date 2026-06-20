# 架构说明

agent-runbook MVP 是一个静态文件知识库，不需要服务端、数据库或构建步骤。

## 组件

- `runbooks/index.json`：机器可读入口，列出首批 runbook 的 id、标题、路径、触发词、owner skill 和风险等级。
- `runbooks/*.md`：人类和 agent 都可读的操作手册。每篇必须带 frontmatter，并保持统一章节。
- `schemas/runbook.schema.json`：文档性 JSON schema，用来描述 frontmatter 约定，不要求安装外部校验器。
- `scripts/validate-runbooks.sh`：唯一内置校验入口，使用 bash 和 Python 标准库。
- `templates/`：新增 runbook 和 prompt 时的起点。
- `docs/`：维护架构和写作规则。

## 数据流

1. 作者新增或修改 runbook。
2. 作者同步更新 `runbooks/index.json`。
3. 本地运行 `bash scripts/validate-runbooks.sh`。
4. CI 在 push 和 pull request 上运行同一命令。

## 设计约束

- 静态优先：Markdown、JSON、bash、Python stdlib 即可工作。
- 引用优先：只引用 skill 名称和边界，不复制 `opencode-skills` 的正文。
- 可停止：每篇 runbook 必须说明停止条件。
- 可验证：每篇 runbook 必须说明验证命令。

## 扩展方向

- 增加更多 runbook 分类索引。
- 为 schema 增加正式校验器。
- 生成静态站点，但不改变 Markdown 作为源文件的事实。
