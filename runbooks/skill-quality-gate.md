---
id: skill-quality-gate
title: Skill 质量门
triggers:
  - 校验 skill
  - validate-feed
  - validate-skills
  - Vercel email failure
owner_skills:
  - skill-extraction-workflow
  - company-skills-sync
risk_level: medium
---

# Skill 质量门

用于在发布或同步 skill 前做结构、链接和告警边界检查。写作规则见 [作者指南](../docs/authoring-guide.md)。

## 何时使用

- 新增、修改、同步公司 skill。
- 需要运行 `bash scripts/validate-feed.sh` 或 `bash scripts/validate-skills.sh`。
- 需要判断校验输出中 warnings 与 errors 的处理方式。

## 不适用

- 只是在业务项目里调用某个 skill。
- 只写普通项目文档，不涉及 skill 包。
- 要诊断 opencode 本地环境时，改用 [Opencode Doctor](opencode-doctor.md)。

## 输入证据

- 被检查的 skill 路径或 feed 路径。
- `bash scripts/validate-feed.sh`、`bash scripts/validate-skills.sh` 的完整输出。
- frontmatter、相对链接、引用文件清单。
- 如涉及 Vercel email failure，记录失败状态、head SHA、commit author email 和平台返回信息。

## 执行流程

1. 确认本次是 skill 质量检查，不复制或改写无关 skill 正文。
2. 检查 frontmatter：名称、描述、触发范围、边界说明必须清晰。
3. 运行 `bash scripts/validate-feed.sh` 检查 feed 或索引结构。
4. 运行 `bash scripts/validate-skills.sh` 检查每个 skill 的文件、链接和格式。
5. 区分 errors 与 warnings：errors 阻断发布；warnings 需要解释、修复或明确接受。
6. 检查相对链接、脚本路径、资源引用是否存在。
7. Vercel email failure 先读 status description；若是 commit author email 无法匹配 GitHub 账号，优先用 GitHub noreply 邮箱重建提交或创建替代 PR，不把它误判为 skill 内容失败。
8. 输出结论：通过、阻断项、可接受告警、后续动作。

## 必须调用的 skill

- `skill-extraction-workflow`：当本次要沉淀或修改 skill 规则时使用。
- `company-skills-sync`：当任务是同步公司 skill 到本地时使用。

## 验证命令

```bash
bash scripts/validate-feed.sh
bash scripts/validate-skills.sh
```

如果仓库提供包装脚本，优先使用仓库脚本，并在结果里标注实际命令。

## 常见失败

- 只看最后一行，漏掉中间的 error。
- 把 warning 当成完全通过，不做解释。
- frontmatter 触发词过宽，导致误路由。
- 相对链接指向本地私有路径，换环境后失效。
- 把 Vercel email failure 归因到 skill 内容，而没有检查 commit author email。

## 停止条件

- `validate-feed` 或 `validate-skills` 出现 error。
- 缺少必要 frontmatter，或触发范围无法判断。
- Vercel email failure 的 status description 未读取，或 commit author email 问题未处理。
- 无法取得完整校验输出。

## 可复用 Prompt

```text
请按 Skill 质量门检查这些 skill：收集 validate-feed 和 validate-skills 的完整输出；检查 frontmatter、相对链接和资源引用；errors 阻断发布，warnings 逐条解释；Vercel email failure 先读 status description 和 commit author email，不复制 skill 正文。
```
