---
id: web-project-quality-assessment
title: Web project quality assessment
summary: Web 项目质量评估 runbook，先识别技术选型、渲染模式、项目方向和交付目标，再选择检查策略。
triggers:
  - Web 项目质量
  - 前端质量检查
  - React 项目审查
  - Next.js 项目审查
  - Vue 项目审查
  - Nuxt 项目审查
  - WebView H5 检查
  - 微前端质量
  - 组件库质量
  - 管理后台质量
  - 项目质量评估
  - quality assessment
  - frontend audit
owner_skills:
  - web-react-dev
  - product-ui-ux-design
  - testing-strategy
  - defect-diagnosis
  - platform-observability
  - platform-release-and-rollout
  - web-perf
risk_level: medium
---

# Web project quality assessment

用于 Web 项目质量检查、前端审查和交付前质量评估。先识别技术选型、渲染模式、项目方向和交付目标，再选择检查策略。不要把所有项目套成 React checklist。

## 何时使用

- 用户要求做 Web 项目质量评估、前端审查或项目健康检查。
- 需要判断 React、Next.js、Vue、Nuxt、静态站、组件库、WebView/H5、微前端等项目的质量风险。
- 需要输出 findings 分级、修复方向和验证方式。
- 需要决定哪些检查能确定性执行，哪些只能人工审查。

## 不适用

- 需要实现功能、修 bug、推送、部署或监控闭环；交给对应开发或交付 runbook。
- 需要生产发布、部署健康验证或回滚判断；后续使用 [Web delivery lifecycle](web-delivery-lifecycle.md)。
- 只做 UI 视觉稿评审，不检查代码、交互状态或可访问性。
- 只做后端服务、移动端 App 或小程序质量评估。

## 输入证据

- 仓库路径、分支、目标范围、用户关心的页面或模块。
- `package.json`、锁文件、构建配置、框架配置、路由结构。
- 技术选型：React/Vite SPA、Next.js、Vue/Nuxt、静态站、文档站、组件库、管理后台、控制台、H5/WebView、微前端。
- 渲染模式：SPA、SSR、SSG、ISR/revalidate、Edge runtime、static export、WebView/H5。
- 项目方向：官网/营销页、文档站、管理后台、控制台/SaaS、数据看板、组件库、H5/WebView、微前端、内部门户。
- 可用脚本：lint、typecheck、test、build、E2E、bundle analyze、link check、dependency audit、secret scan。
- 现有证据：CI 结果、测试报告、性能报告、依赖审计、错误日志、监控埋点、发布说明。

## 执行流程

1. 界定审查范围：全仓、单应用、单页面、组件库、关键用户路径或 PR diff。
2. 识别技术选型，不按单一框架套模板。
3. 识别渲染模式，确认质量风险来自客户端、服务端、构建期、边缘运行时还是宿主 WebView。
4. 识别项目方向，调整质量权重。
5. 读取现有脚本和 CI 配置，只选择仓库已有或目标明确的确定性检查。
6. 运行可执行检查，记录命令、结果、失败证据和未执行原因。
7. 做 agent review：审查组件边界、状态所有权、API client、权限、错误态、加载态、可访问性、性能风险、监控埋点和测试覆盖。
8. 分级 findings：Blocker、High、Medium、Low。
9. 每个 Blocker/High finding 必须写修复方向和验证方式。
10. 缺证据时标记 `not checked`、`blocked` 或 `not configured`，不得写“通过”。

## 必须调用的 skill

按场景调用；不代表每次都全量加载。

- `web-react-dev`：审查 React、Next.js、Vite 等 Web 客户端代码结构、状态和数据流。
- `product-ui-ux-design`：审查页面状态完整性、交互、空态、错误态、可访问性和体验一致性。
- `testing-strategy`：选择测试层级，判断用例、mock、E2E 和回归覆盖是否匹配风险。
- `defect-diagnosis`：确定性检查失败时，读取一手失败证据再判断根因。
- `platform-observability`：审查日志、指标、trace、错误上报和告警准备度。
- `platform-release-and-rollout`：审查发布准备、灰度、回滚和环境 gate；不在本 runbook 执行发布。
- `web-perf`：需要页面加载、Core Web Vitals、bundle、网络链路或渲染性能分析时使用。

## 验证命令

优先使用仓库现有脚本。不要强造命令；没有配置就标记 `not configured`。

常见候选：

```bash
npm run lint
npm run typecheck
npm test
npm run build
npm run e2e
npm run analyze
npm run link-check
npm audit
```

如项目使用 pnpm、yarn、bun 或 monorepo task runner，按仓库约定替换。secret scan、dependency audit、bundle analyze、link check 只在仓库已有配置或任务目标明确时执行。

## 常见失败

- 把所有 Web 项目都按 React SPA 审查，漏掉 SSR、SSG、ISR、Edge runtime 或 WebView 风险。
- 把风格偏好当质量问题，输出不可验证的主观建议。
- 只跑 lint/build，就声称项目质量通过。
- 缺少脚本或权限时写“通过”，没有标记 `not checked`、`blocked` 或 `not configured`。
- 把部署、生产健康或监控告警问题继续塞进质量评估，未转到 Web delivery lifecycle。
- Blocker/High finding 没有修复方向和验证方式。

## 停止条件

- 仓库无法读取，或没有用户授权访问目标代码。
- 目标范围不清，且无法从任务描述或仓库结构判断审查对象。
- 确定性检查失败，但无法取得失败命令、exit code、日志或报告。
- 发现凭据泄露、权限绕过、生产发布风险或高危安全问题；先汇报 Blocker，不继续扩大范围。
- 用户要求执行生产发布、部署验证或回滚；停止本 runbook，转到 Web delivery lifecycle 并等待明确授权。

## Scope classification

先填四项，再开始审查：

- 技术选型：React/Vite SPA、Next.js、Vue/Nuxt、静态站、文档站、组件库、管理后台、控制台、H5/WebView、微前端。
- 渲染模式：SPA、SSR、SSG、ISR/revalidate、Edge runtime、static export、WebView/H5。
- 项目方向：官网/营销页、文档站、管理后台、控制台/SaaS、数据看板、组件库、H5/WebView、微前端、内部门户。
- 交付目标：上线前审查、PR 审查、重构评估、性能评估、安全/权限评估、测试覆盖评估、发布准备评估。

## Strategy by project type

| 类型 | 重点 | 高风险信号 |
| --- | --- | --- |
| React/Vite SPA | 路由、状态所有权、API client、bundle、加载态和错误态 | 全局状态承载局部状态；API 调用散落组件；首屏 bundle 过大 |
| Next.js | Server/Client 边界、数据获取、缓存、revalidate、middleware、Edge runtime | 在客户端暴露服务端密钥；缓存策略不清；Server Component 边界错误 |
| Vue/Nuxt | composition 边界、store、插件、SSR/SSG、路由守卫 | 服务端渲染与客户端状态不一致；权限守卫只在前端做 |
| 静态站/文档站 | 构建、链接、搜索、内容路由、SEO、可访问性 | 断链、生成失败、无 404/重定向策略、内容搜索不可用 |
| 组件库 | API 稳定性、类型、样式隔离、可访问性、示例和测试 | breaking change 未标注；组件状态缺失；样式污染宿主 |
| 管理后台/控制台 | 权限、表单、表格、错误处理、审计、批量操作 | 前端隐藏代替权限控制；危险操作无确认或回滚 |
| H5/WebView | 宿主能力、兼容性、弱网、返回栈、埋点、降级 | 依赖宿主 API 但无 fallback；WebView 缓存导致版本漂移 |
| 微前端 | 应用边界、依赖共享、路由隔离、样式隔离、发布协同 | 子应用互相污染；共享依赖版本冲突；灰度无法单独回滚 |

## Rendering mode checks

- SPA：检查首屏加载、路由懒加载、错误边界、客户端权限和 API 错误处理。
- SSR：检查服务端数据获取、请求隔离、缓存、hydration mismatch 和服务端异常处理。
- SSG：检查构建期数据、断链、内容变更流程和 static export 兼容性。
- ISR/revalidate：检查 revalidate 触发、缓存失效、stale 数据、失败重试和回退页面。
- Edge runtime：检查 runtime API 限制、冷启动、区域差异、密钥访问和 observability。
- WebView/H5：检查宿主 API、兼容版本、网络状态、返回栈、分享、登录态和降级。

## Quality dimensions

- 工程结构：目录边界清晰；业务、组件、数据访问、工具函数不过度耦合。
- 类型与边界：关键数据有类型；外部输入、接口响应和环境变量有校验边界。
- 状态管理：状态归属明确；服务端状态、表单状态、URL 状态和 UI 状态不混用。
- API 集成：API client 集中；错误、重试、取消、鉴权和超时策略可追踪。
- UI/UX 状态完整性：加载、空态、错误态、禁用态、成功态、撤销或重试路径完整。
- 可访问性：语义标签、键盘操作、焦点管理、颜色对比、表单 label、ARIA 使用合理。
- 性能：首屏、路由切换、bundle、图片、字体、列表渲染、缓存和网络 waterfall 有证据。
- 安全与权限：前端不承载权限真相；密钥不进客户端；危险操作有确认和审计线索。
- 测试策略：测试覆盖关键行为；mock 不掩盖真实集成风险；E2E 覆盖关键路径。
- 可观测性/发布准备：关键路径有错误上报、日志、指标、trace 或埋点；发布与回滚条件可说明。

## Deterministic checks first

- 先找现有脚本，不凭经验发明命令。
- 优先级：lint、typecheck、test、build、E2E、bundle analyze、link check、dependency audit、secret scan。
- 运行后记录：命令、退出码、摘要、报告路径、失败第一条真实错误。
- 未配置写 `not configured`。
- 缺权限写 `blocked`。
- 未在本次范围执行写 `not checked`，并说明原因。

## Agent review checks

- 组件边界：组件职责单一；容器、展示、表单、数据访问边界清楚。
- 状态所有权：状态放在最小必要作用域；URL、缓存、表单和全局状态不互相污染。
- API client：请求、鉴权、错误映射、重试、取消和响应类型集中处理。
- 权限：页面守卫、按钮显隐、后端权限和错误反馈一致；不把隐藏 UI 当授权。
- 错误态：接口失败、空数据、权限不足、超时、离线和部分失败可恢复。
- 加载态：首屏、局部刷新、分页、批量操作和提交中状态不造成误操作。
- 可访问性：键盘路径、焦点回到合理位置；弹窗、表单、表格和导航可读可操作。
- 性能风险：大依赖、同步阻塞、重复请求、无虚拟列表、未优化图片和无限重渲染。
- 监控埋点：关键路径错误、核心交互、性能点和发布版本可关联。
- 测试覆盖：测试验证用户行为和边界，不只验证实现细节。

## Findings grading

- Blocker：阻断交付或存在高危风险。
  - 例子：构建失败；类型检查无法通过；密钥进入客户端；权限绕过；关键路径不可用。
  - 必须包含修复方向和验证方式。
- High：不一定阻断当前审查，但会显著影响正确性、安全、体验、性能或可维护性。
  - 例子：SSR 缓存导致用户数据串扰；错误态缺失导致关键操作无反馈；E2E 缺失覆盖支付或权限路径。
  - 必须包含修复方向和验证方式。
- Medium：影响局部质量，建议排入近期修复。
  - 例子：组件职责偏大；列表性能有风险但未达阻断；部分表单可访问性不足。
- Low：小范围可维护性、文案、轻微体验或清理项。
  - 例子：重复工具函数；非关键页面 loading 文案不一致；测试命名不清。

不要把个人风格偏好列为 finding。只收录影响正确性、可维护性、体验、性能、安全或交付的证据。

## Report format

```text
范围：
- 技术选型：<React/Vite SPA | Next.js | Vue/Nuxt | 静态站 | 组件库 | H5/WebView | 微前端 | 其他>
- 渲染模式：<SPA | SSR | SSG | ISR/revalidate | Edge runtime | static export | WebView/H5>
- 项目方向：<官网/文档站/管理后台/控制台/数据看板/组件库/H5/微前端/内部门户>
- 审查目标：<上线前/PR/重构/性能/安全/测试/发布准备>

确定性检查：
- 已运行：<命令 + 结果 + 报告路径>
- not configured：<缺少哪些脚本或工具>
- blocked：<缺少哪些权限或依赖>
- not checked：<本次未检查项和原因>

Findings：
- [Blocker] <问题>
  - 证据：<文件/命令/日志/截图/报告>
  - 影响：<正确性/可维护性/体验/性能/安全/交付>
  - 修复方向：<建议>
  - 验证方式：<命令/测试/人工验证>
- [High|Medium|Low] <同上>

结论：
- 质量状态：<通过/有条件通过/不通过/证据不足>
- 后续流程：<如涉及部署或生产健康，转 Web delivery lifecycle>
```

## 可复用 Prompt

```text
请按 Web project quality assessment runbook 审查这个 Web 项目：先识别技术选型、渲染模式、项目方向和审查目标；不要套单一 React checklist；优先运行仓库已有的 lint/typecheck/test/build/E2E/bundle analyze/link check/dependency audit/secret scan；缺证据时标记 not checked、blocked 或 not configured，不得写通过；agent review 覆盖组件边界、状态所有权、API client、权限、错误态、加载态、可访问性、性能风险、监控埋点和测试覆盖；findings 按 Blocker/High/Medium/Low 分级，每个 Blocker/High 带修复方向和验证方式；如发现部署或生产健康问题，只指向 Web delivery lifecycle 作为后续流程。
```
