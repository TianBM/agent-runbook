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

## 静态分发形态

Vercel 发布时不需要构建步骤，仓库文件按静态资源分发：

- `/runbooks/index.json` 是 agent 的稳定机器入口，不应长期缓存。
- `/runbooks/*.md` 是具体 runbook 正文，agent 通过 index 中的 `path` 字段读取。
- `/schemas/`、`/docs/` 和 `/templates/` 作为辅助资料直接按路径访问。
- `/README.md` 保留为远程可读的项目说明入口。

推荐组织方式是“索引先行、正文按需读取”：索引只保存发现和路由所需的轻量字段，Markdown 保留完整执行流程。这样静态站点无需 runtime/search API，也能让 agent 从稳定 base URL 获得可验证的 runbook。

## 设计约束

- 静态优先：Markdown、JSON、bash、Python stdlib 即可工作。
- 引用优先：只引用 skill 名称和边界，不复制 `opencode-skills` 的正文。
- 可停止：每篇 runbook 必须说明停止条件。
- 可验证：每篇 runbook 必须说明验证命令。

## 生态边界

- `opencode-starter`：本地入口，负责安装、更新、项目初始化和 doctor 检查。
- `opencode-skills`：触发与 owner 路由层，负责技能触发规则、流程边界和技能质量门禁。
- `agent-runbook`：稳定流程层，负责沉淀可按步骤执行的操作流程、证据要求和真实交付路径。

近期扩展按归属落到对应仓库：

- starter 侧优先补 doctor 与版本发布闭环。
- skills 侧优先补索引生成和触发治理。
- runbook 侧优先补内网交付、CI 失败排障、发布回滚等稳定流程。

不做动态搜索服务、数据库 registry、agent runtime、全量 runbook 注入或复杂遥测。继续保持静态、可审、按需读取。

## 扩展方向

- 增加更多 runbook 分类索引。
- 为 schema 增加正式校验器。
- 生成静态站点，但不改变 Markdown 作为源文件的事实。
