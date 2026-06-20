---
id: client-architecture-constraint-check
title: Client architecture constraint check
summary: Web/App 客户端开发前的架构约束检查 runbook，聚焦 API 合约、状态归属、有限值、宿主运行时和验证证据边界。
triggers:
  - 客户端架构约束
  - 前端架构约束
  - App 架构约束
  - Web/App 开发前检查
  - API 合约边界
  - 状态归属
  - WebView contract
  - verification evidence
  - client architecture
owner_skills:
  - web-react-dev
  - app-cross-platform-dev
  - testing-strategy
  - product-ui-ux-design
  - platform-observability
  - platform-release-and-rollout
risk_level: high
---

# Client architecture constraint check

用于 Web/App 客户端开发前的架构约束检查。流程是识别、取证、分流 owner skills、形成验证矩阵，再按停止条件卡住高风险缺口。

## 何时使用

- 开始 Web、H5、WebView、移动 App 或跨端客户端开发前，需要先确认架构边界。
- 用户提到 API 合约边界、状态归属、有限值、宿主运行时、验证证据或 WebView contract。
- 需求涉及前端与后端、宿主 App、设计、测试、发布或监控之间的边界协作。
- 需要决定下一步应交给哪个 owner skill，而不是直接写代码或选型。

## 不适用

- 不替代 `web-react-dev`、`app-cross-platform-dev`、`testing-strategy`、`product-ui-ux-design` 或后端 owner skills。
- 不写 React、Flutter、React Native、原生 App、Next、Vite 或状态库最佳实践大全。
- 不替项目决定 Next/Vite/Flutter/RN/Native、状态库、API client 或目录结构选型。
- 不负责修 bug、写功能、出 UI 方案、写测试方案或做发布回滚；识别到这些工作后转交对应 owner。

## 输入证据

- 需求范围：页面、端类型、用户路径、宿主环境、目标平台和交付阶段。
- API 证据：接口文档、OpenAPI/GraphQL/protobuf、错误码、鉴权、分页、缓存、幂等、版本兼容说明。
- 状态证据：服务端状态、URL 状态、表单状态、UI 临时状态、全局状态、持久化状态的 owner 和写入点。
- 有限值证据：枚举、状态机、后端常量、设计态、权限值、feature flag、错误类型和降级分支。
- 宿主证据：浏览器、WebView、Native bridge、系统权限、离线/弱网、推送、相机、定位、存储、深链和版本能力矩阵。
- 验证证据：现有 lint、typecheck、test、build、E2E、契约测试、截图、设备验证、CI、监控或发布证据。

## 执行流程

1. 识别客户端类型：Web、H5/WebView、Flutter、React Native、原生 App、混合栈或共享组件库。
2. 识别 P0 约束，不做框架选型判断。
3. 对每个 P0 约束写入证据状态：`confirmed`、`missing`、`ambiguous`、`blocked` 或 `not applicable`。
4. 缺证据时先取证：读项目文档、接口契约、设计稿状态、测试脚本、CI 或宿主能力说明。
5. 分流 owner skills：按代码、设计、测试、监控、发布或后端契约归属转交，不在本 runbook 内替 owner 下实现结论。
6. 形成验证矩阵：每条 P0 约束必须有 owner、证据、验证方式和停止条件。
7. 只在 P0 约束有明确 owner 和可执行验证方式后，进入实现或评审。

### P0 约束

| 约束 | 必须确认 | 缺口处理 |
| --- | --- | --- |
| API contract boundary | 请求/响应、错误码、鉴权、分页、缓存、重试、超时、版本兼容和权限真相由谁定义 | 契约不清时转后端 owner；客户端不得用猜测字段或隐藏 UI 代替权限 |
| State ownership boundary | 服务端状态、URL 状态、表单状态、UI 临时状态、全局状态和持久化状态各有单一 owner | 同一状态多处写入时暂停实现，先收敛 owner 和同步规则 |
| Finite-value / enum boundary | 枚举、状态机、错误类型、权限值、设计态和 feature flag 有真值源与未知值策略 | 前后端枚举漂移或未知值无兜底时，先补契约与测试 |
| Runtime host boundary | 浏览器、WebView、Native bridge、OS 权限、离线/弱网、版本能力和降级路径已说明 | 宿主能力缺证据时转 App/WebView owner；不得假设所有宿主 API 恒可用 |
| Verification evidence boundary | 每个关键路径有可运行命令、测试、设备验证、截图、CI、监控或发布证据 | 无证据时不得报告“通过”；只能写 `not checked`、`blocked` 或 `not configured` |

### P1 约束

- Observability/support trace：关键路径错误、版本、用户操作或 trace id 是否可定位。
- Security/privacy/permission：权限真相、敏感信息、设备权限和隐私提示是否有 owner。
- Release/rollback/feature flag：灰度、回滚、开关、兼容窗口和 kill switch 是否可说明。
- Design state matrix：加载、空态、错误态、禁用态、成功态和异常分支是否覆盖。
- Cross-platform shared-code boundary：共享代码能否承载平台差异，不能承载时是否有分叉边界。

## 必须调用的 skill

按缺口调用，不代表每次全量加载。

- `web-react-dev`：Web、H5、WebView 页面或 React/Next/Vite 等客户端实现边界。
- `app-cross-platform-dev`：Flutter、React Native、原生 App、Native bridge、设备权限或宿主能力边界。
- `testing-strategy`：为 P0 约束选择契约测试、单元、组件、E2E、设备验证或回归层级。
- `product-ui-ux-design`：设计状态矩阵、交互状态、错误态、权限态和可访问性边界。
- `platform-observability`：support trace、错误上报、指标、日志、trace 和排障证据边界。
- `platform-release-and-rollout`：feature flag、灰度、回滚、发布兼容和生产变更 gate。
- 后端 owner skills：API 契约、权限真相、枚举真值源、错误码、幂等或数据一致性属于后端时必须转交。

## 验证命令

优先使用仓库已有脚本，不硬造命令。候选命令：

```bash
npm run lint
npm run typecheck
npm test
npm run build
npm run e2e
```

移动端或跨端项目按仓库约定替换，例如 `flutter test`、`flutter analyze`、`xcodebuild test`、`./gradlew test`、`./gradlew connectedCheck`。没有配置时写 `not configured`；需要设备、账号、宿主 App 或 CI 权限时写 `blocked` 并列出缺口。

## 常见失败

- 把本 runbook 写成某个框架的最佳实践清单，覆盖了 owner skill 的职责。
- 未确认 API 合约就直接按样例响应写字段、枚举或错误处理。
- 同一状态同时由 URL、store、表单、缓存和组件 state 写入。
- 枚举只处理已知 happy path，没有未知值、兼容版本或后端新增值策略。
- WebView 或 Native bridge 能力未探测，默认所有宿主、系统版本和权限都可用。
- 只有 lint/build 输出，却声称架构约束通过。
- 缺少证据时写“已确认”，没有标记 `missing`、`ambiguous`、`blocked` 或 `not configured`。

## 停止条件

- P0 约束任一项缺 owner、缺真值源或缺验证方式。
- API 契约、权限真相、枚举真值源或宿主能力由猜测得出。
- 关键路径涉及安全、隐私、支付、资损、登录态、权限或生产发布，但验证证据不足。
- 需要项目级选型决策，却没有决策记录、技术方案或用户授权。
- 需要生产发布、灰度、回滚、权限变更或后端契约变更，但未获得明确 owner 接手。

## 验证矩阵

```text
范围：<Web/H5/WebView/Flutter/RN/Native/共享组件库>

P0 约束：
- API contract boundary
  - 状态：<confirmed|missing|ambiguous|blocked|not applicable>
  - owner：<客户端 owner / 后端 owner / 平台 owner>
  - 证据：<契约链接、字段、错误码、权限说明、版本说明>
  - 验证：<命令、测试、设备验证、CI、人工检查>
  - 停止条件：<未满足时不得进入实现或发布的条件>

- State ownership boundary
  - 状态：<...>
  - owner：<...>
  - 证据：<...>
  - 验证：<...>
  - 停止条件：<...>

- Finite-value / enum boundary
  - 状态：<...>
  - owner：<...>
  - 证据：<...>
  - 验证：<...>
  - 停止条件：<...>

- Runtime host boundary
  - 状态：<...>
  - owner：<...>
  - 证据：<...>
  - 验证：<...>
  - 停止条件：<...>

- Verification evidence boundary
  - 状态：<...>
  - owner：<...>
  - 证据：<...>
  - 验证：<...>
  - 停止条件：<...>

P1 备注：<observability/security/release/design/shared-code 的缺口和转交 owner>
结论：<可进入实现|需补证据|需 owner 决策|停止>
```

## 可复用 Prompt

```text
请按 Client architecture constraint check runbook 做 Web/App 客户端开发前检查：先识别端类型和宿主环境；不要替项目决定 Next/Vite/Flutter/RN/Native、状态库或 API client 选型；只检查 API contract boundary、State ownership boundary、Finite-value / enum boundary、Runtime host boundary、Verification evidence boundary 五个 P0 约束；每项写 confirmed/missing/ambiguous/blocked/not applicable、owner、证据、验证方式和停止条件；缺口按 web-react-dev、app-cross-platform-dev、testing-strategy、product-ui-ux-design、platform-observability、platform-release-and-rollout 或后端 owner skills 分流；没有证据不得写通过。
```
