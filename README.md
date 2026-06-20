# agent-runbook MVP

agent-runbook 是一个静态知识库项目，用来给 AI agent 提供“任务级操作手册”。它不替代 skill，也不承载业务代码；它把常见任务拆成可验证、可停止、可复用的 runbook，帮助 agent 在执行前知道该收集哪些证据、调用哪些 owner skill、何时停止。

## 项目定位

- 面向 AI agent 的中文 runbook 知识库。
- 每篇 runbook 都应短小、可执行、结构统一。
- 通过 `runbooks/index.json` 作为入口索引，通过脚本做离线校验。
- 只引用 skill 名称、边界和触发条件，不复制 `opencode-skills` 的 skill 正文。

## 边界

- 不包含可执行 agent 框架。
- 不包含 opencode 配置模板。
- 不沉淀公司 skill 的完整内容。
- 不替代项目本身的 README、AGENTS.md 或 CI 文档。

## 目录结构

```text
.
├── README.md
├── docs/
│   ├── architecture.md
│   └── authoring-guide.md
├── runbooks/
│   ├── index.json
│   ├── git-pr-lifecycle.md
│   ├── skill-quality-gate.md
│   ├── opencode-doctor.md
│   └── pr-watch-and-continue.md
├── schemas/
│   └── runbook.schema.json
├── scripts/
│   ├── validate-runbooks.sh
│   └── watch-pr.sh
├── templates/
│   ├── after-merge-script.md
│   ├── prompt-template.md
│   ├── runbook-template.md
│   └── watcher-config.md
└── .github/workflows/ci.yml
```

## 如何验证

本项目校验不依赖外部包，只需要 bash 和 Python 标准库：

```bash
bash scripts/validate-runbooks.sh
```

校验内容包括：索引 JSON、frontmatter 必填字段、id 唯一性、章节完整性、markdown 相对链接、行尾空白等。成功输出 `OK`，失败输出 `ERROR` 并返回非零退出码。

## Vercel 静态发布与远程使用

本仓库可以作为 Vercel 静态站点发布，不需要构建步骤。发布后，Markdown、JSON、schema、docs 和 templates 都按仓库路径直接暴露为 URL；`vercel.json` 为 `/runbooks/**` 设置 `no-cache, no-store, must-revalidate`，并为主要辅助文档目录设置低缓存，避免 agent 长期读取旧索引或旧正文。

推荐 agent 使用稳定 base URL 作为入口：

```text
https://runbooks.junyou.me
```

查询流程采用 index-first：

1. 读取 `{base_url}/runbooks/index.json`。
2. 根据 `triggers`、`owner_skills`、`risk_level` 等字段选择 runbook。
3. 按 entry 的 `path` 读取 `{base_url}/{entry.path}`。
4. 根据 Markdown 正文中的输入证据、执行流程、验证命令和停止条件执行。

更多字段语义和使用建议见 [Agent 远程查询说明](docs/agent-query.md)。本项目不提供 runtime/search API，也不生成前端页面；搜索和筛选由调用方 agent 在本地完成。

远程 smoke 校验示例：

```bash
bash scripts/smoke-remote-runbooks.sh https://runbooks.junyou.me
bash scripts/smoke-remote-runbooks.sh --expect-local runbooks/index.json https://runbooks.junyou.me
```

## 与相关项目的关系

- `opencode-starter`：负责 opencode 项目初始化、配置示例和启动约定；本项目只提供任务 runbook，可被 starter 链接或作为后续阅读材料。
- `opencode-skills`：负责可调用 skill 的正文、触发规则和流程门；本项目只引用 skill 名称与边界，不复制 skill 正文。
- `ops-agent`：负责运维 agent 的运行逻辑、工具编排和环境操作；本项目提供人工和 agent 都能阅读的操作步骤，作为执行前后的知识库。

## 首批 runbook

- [Git PR 生命周期](runbooks/git-pr-lifecycle.md)
- [Skill 质量门](runbooks/skill-quality-gate.md)
- [Opencode Doctor](runbooks/opencode-doctor.md)
- [PR 监听/合并后自动继续](runbooks/pr-watch-and-continue.md)

## 辅助脚本

- `scripts/watch-pr.sh`：使用 `gh pr view` 轮询 PR checks 或 merged 状态；默认不自动 merge，支持在 PR merged 后执行受控的低风险 `--after-merge` 命令。
- `scripts/smoke-remote-runbooks.sh`：校验 Vercel 等静态发布地址上的 `runbooks/index.json` 和每个 runbook path 是否可访问，可选对比本地 index 的 `id/path` 集合。
