# Agent 远程查询说明

本项目可以直接作为 Vercel 静态站点发布。发布后，agent 只需要一个稳定的 base URL，就能读取 `runbooks/index.json` 并按索引定位具体 runbook Markdown。

## Base URL

Base URL 是 Vercel 分配或绑定域名后的站点根地址，例如：

```text
https://runbooks.junyou.me
```

调用时不要依赖目录列表或 HTML 页面，直接拼接公开静态文件路径：

```text
{base_url}/runbooks/index.json
{base_url}/runbooks/git-pr-lifecycle.md
```

## Index-first 查询流程

推荐所有 agent 先读索引，再读具体 runbook：

1. 读取 `{base_url}/runbooks/index.json`。
2. 校验返回值是数组，每个 entry 至少包含 `id`、`title`、`path`、`triggers`、`owner_skills`、`risk_level`。
3. 根据用户任务、关键词或所需 owner skill，在本地匹配 entry。
4. 使用 `{base_url}/{entry.path}` 读取 Markdown 正文。
5. 按正文中的输入证据、执行流程、必须调用的 skill、验证命令和停止条件执行。

这种方式让远端发布保持静态，同时让 agent 拥有稳定的机器入口。

## 字段语义

- `id`：稳定标识，用于日志、引用和本地缓存键。
- `title`：人类可读标题，可展示给用户或写入执行记录。
- `path`：相对站点根路径的 Markdown 文件位置。agent 应以 base URL 拼接该值，不要猜测文件名。
- `triggers`：适合匹配用户输入的触发词或短语。
- `owner_skills`：执行该 runbook 时通常需要调用或遵守的 skill 名称。
- `risk_level`：风险等级，当前约定为 `low`、`medium` 或 `high`。

## 推荐使用方式

- 将 base URL 固定在 agent 配置、系统提示或项目文档中。
- 每次任务开始时读取最新 `runbooks/index.json`；不要长期缓存索引。
- 对命中的 entry 再读取 Markdown 正文，避免把所有 runbook 常驻上下文。
- 如果需要离线兜底，可缓存上次成功读取的 index 和 Markdown，但应标记来源 URL 与抓取时间。
- 发布后使用 `scripts/smoke-remote-runbooks.sh` 检查远端索引和每个 `path` 是否可访问。

## 非目标

本项目不提供 runtime API、搜索服务、向量索引、鉴权层或前端页面。Vercel 只负责静态分发 Markdown、JSON、schema、docs 和 templates；查询、筛选和执行决策由调用方 agent 在本地完成。
