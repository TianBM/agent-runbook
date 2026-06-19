---
id: opencode-doctor
title: Opencode Doctor
triggers:
  - opencode doctor
  - doctor --json
  - 环境诊断
  - 配置缺失
owner_skills:
  - customize-opencode
risk_level: low
---

# Opencode Doctor

用于只读诊断 opencode 环境状态，优先收集 `doctor` 与 `doctor --json` 输出，再决定是否需要人工授权修复。

## 何时使用

- 用户说 opencode 配置异常、工具不可用或环境缺项。
- 需要解释 `OK`、`MISSING`、`WARN`、`INFO` 状态。
- 需要生成可复现的诊断摘要。

## 不适用

- 修改业务项目代码。
- 安装或发布普通应用依赖。
- 未经授权直接改写 opencode 配置、agent、skill 或 MCP 配置。

## 输入证据

- `opencode doctor` 输出。
- `opencode doctor --json` 输出。
- 当前 opencode 配置路径、版本号、操作系统。
- 用户看到的实际错误信息或失败命令。

## 执行流程

1. 先运行只读诊断命令，不修改文件。
2. 同时收集人类可读输出和 JSON 输出，便于对照。
3. 按状态分类：`OK` 表示通过；`MISSING` 表示缺少必要项；`WARN` 表示有风险但未必阻断；`INFO` 表示提示信息。
4. 对每个 `MISSING` 记录缺少对象、影响范围和可能修复命令。
5. 对每个 `WARN` 记录风险和是否需要用户确认。
6. 常见修复包括补配置文件、刷新 auth、安装缺失 CLI、修正 MCP 路径。
7. 在执行任何写入、安装或登录前，先向用户说明影响并等待确认。

## 必须调用的 skill

- `customize-opencode`：当需要创建或修改 opencode 配置、agent、skill、plugin、MCP server 或 permission rule 时使用。

## 验证命令

```bash
opencode doctor
opencode doctor --json
```

修复后再次运行相同命令，对比状态变化。

## 常见失败

- 只看 `doctor` 文本输出，漏掉 JSON 里的字段。
- 把 `WARN` 当作阻断错误，或把 `MISSING` 当作提示。
- 未授权就写入 `~/.config/opencode/`。
- 修复后没有重新运行 doctor。

## 停止条件

- 诊断命令本身不存在或无法运行：停止并报告安装状态。
- 需要登录、安装或写配置：停止等待用户确认。
- JSON 输出无法解析：保留原始输出，停止自动判断。
- 修复可能影响全局配置或其他项目：停止并说明影响面。

## 可复用 Prompt

```text
请按 Opencode Doctor runbook 做只读诊断：运行 opencode doctor 和 opencode doctor --json；解释 OK/MISSING/WARN/INFO；列出常见修复建议；在任何写入、安装、登录或全局配置变更前先停止并请求确认。
```
