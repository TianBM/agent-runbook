---
id: web-delivery-lifecycle
title: Web delivery lifecycle
summary: Web 项目从编码到部署、监控证据闭环的交付 runbook。
triggers:
  - Web 交付
  - 前端部署
  - CI/CD
  - 公网部署
  - 内网部署
  - 监控证据
owner_skills:
  - web-react-dev
  - worktree-isolation
  - git-commit
  - testing-strategy
  - defect-diagnosis
  - platform-release-and-rollout
  - platform-observability
  - deploy-to-vercel
  - cloudflare
risk_level: high
---

# Web delivery lifecycle

用于把 Web 项目从编码推进到可报告交付。覆盖本地验证、推送、CI/CD、部署、监控证据。生产合并、生产部署、生产发布必须有明确授权。

## 何时使用

- 用户要求实现、修复或交付 Web 项目。
- 需要把改动推送到远端，并观察 CI/CD。
- 需要判断公网或内网部署是否完成。
- 需要用监控、日志、trace 或告警证据支撑交付结论。

## 不适用

- 只读代码分析，不修改、不推送、不部署。
- 只做设计稿、需求评审或测试用例文档。
- 只排查单个线上故障；先走缺陷诊断，再回到本 runbook 做交付闭环。
- 需要安装或配置 Vercel、Cloudflare Pages、GitLab、Jenkins、k8s、Rancher、OTel、ES、Jaeger 等平台；本 runbook 只指导取证与判断。

## 输入证据

- 仓库路径、当前分支、目标分支、远端地址。
- 项目类型：Next.js、Vite、React、静态站点或其他 Web 框架。
- 可用脚本：lint、typecheck、test、build、preview、deploy。
- CI/CD 入口：GitHub Actions、GitLab CI、Jenkins 或其他平台链接。
- 部署目标：公网托管、内网环境、预发、测试或生产。
- 权限边界：能否推送、创建 PR/MR、触发 pipeline、查看部署、查看监控。

## 执行流程

1. 确认不在 main 或默认分支直接开发；需要修改代码时先使用隔离 worktree。
2. 读取项目脚本和已有 README、runbook、CI 配置，确认验证入口。
3. 编码前明确交付范围：页面、组件、接口、配置或部署修复。
4. 修改后先做本地验证；默认不启动 dev server，除非渲染、路由或浏览器行为必须人工确认。
5. 本地验证通过后，检查 `git status`、`git diff`、最近提交记录，只提交预期文件。
6. 推送功能分支，创建或更新 PR/MR，不开启自动合并。
7. 读取 CI/CD 状态；失败时读取一手失败证据，不只看摘要。
8. CI/CD 通过后选择部署路径：公网或内网。
9. 部署后必须收集访问、日志、trace、指标或告警证据；拿不到权限时明确写入未验证项。
10. 只有本地验证、CI/CD、部署状态、监控证据都闭环，才可报告交付完成。

## 必须调用的 skill

按场景调用；不代表每次都全量加载。

- `web-react-dev`：实现或修改 React、Next.js、Vite 等 Web 客户端代码时使用。
- `worktree-isolation`：任何代码修改、分支、PR/MR 或合并动作前使用。
- `git-commit`：需要创建提交时使用。
- `platform-release-and-rollout`：涉及部署、发布、回滚、灰度或环境推进时使用。
- `platform-observability`：需要判断日志、指标、trace、告警证据是否足够时使用。
- `defect-diagnosis`：CI/CD、部署或线上验证失败时，先读取一手失败证据再定性。

## 验证命令

优先使用项目脚本，不硬造命令。常见顺序：

```bash
npm run lint
npm run typecheck
npm test
npm run build
```

如项目使用 pnpm、yarn、bun、pytest、go test 或其他脚本，按仓库现有配置执行。未运行的命令必须说明原因：耗时过长、缺依赖、缺权限、需要用户确认或不适用。

## 常见失败

- 未读项目脚本，直接运行不存在的命令。
- 为确认页面效果启动 dev server，但没有必要或没有告知用户。
- CI/CD 失败时只看红叉，没有读取失败 job、stage、命令、exit code、第一条真实错误、artifact 和 runner 信息。
- 把部署成功当成交付完成，没有监控、日志、trace 或告警证据。
- 生产发布、生产合并或生产部署未获明确授权。
- 内网平台缺权限，却把“看不到”写成“已验证”。

## 停止条件

- 当前分支是 main 或默认分支，且需要修改代码。
- 本地验证失败，或无法解释失败原因。
- CI/CD 出现失败、取消、超时、手动审批未通过或 runner 异常。
- 部署目标是生产，但用户未明确授权本次生产动作。
- 部署后无法取得任何访问、日志、trace、指标或告警证据。
- 发现凭据、内部域名、IP、集群名或业务名将被写入通用 runbook。

## Phase 1: Inspect the project

- 识别包管理器：`package-lock.json`、`pnpm-lock.yaml`、`yarn.lock`、`bun.lockb`。
- 读取脚本：`package.json`、CI 配置、部署配置、README。
- 识别构建产物：`dist`、`build`、`.next`、`out` 或平台约定目录。
- 识别环境变量需求：只记录变量名和缺失状态，不输出值。
- 识别部署入口：平台项目、CI job、Jenkins job、Helm chart、k8s manifest、Rancher workload 或 CDN 配置。
- 识别权限缺口：推送、CI、部署、日志、监控、trace、告警查看权限。

## Phase 2: Verify locally

- 先跑静态检查：lint、format check、typecheck。
- 再跑测试：单元、组件、集成或端到端测试。
- 最后跑 build；Web 交付至少要证明生产构建可完成。
- 默认不启动 dev server。
- 只有需要人工确认浏览器行为时才启动，并记录原因、地址、关闭方式。
- 失败时保留第一条真实错误，不用后续级联错误替代根因证据。

## Phase 3: Push and watch CI/CD

- 推送前检查差异：无凭据、无无关格式化、无误提交生成物。
- 创建 PR/MR 后记录链接、head SHA、目标分支。
- 观察 CI/CD：job、stage、命令、耗时、runner、artifact。
- 失败时下载或打开日志，定位第一条真实错误和 exit code。
- 需要手动 job 或审批时，先报告等待点，不替用户点击生产发布。
- CI/CD 通过只说明流水线通过，不等于部署完成。

## Phase 4: Choose the deployment path

- 先确认目标环境：预览、测试、预发、生产。
- 先确认授权：生产合并、生产部署、生产发布必须由用户明确授权。
- 先确认路径：公网托管或内网平台。
- 先确认回滚入口：平台回滚、上一个部署、镜像 tag、Helm revision 或 Git revert。

### Public web deployment

可用证据源：Vercel、Cloudflare Pages、Netlify、GitHub Pages、CDN 控制台、平台 CLI 输出、部署 URL、构建日志。

检查项：

- 部署记录指向当前 commit 或 head SHA。
- 构建日志显示成功，未被 cancelled、skipped 或 superseded。
- 预览 URL 或正式 URL 可访问，状态码符合预期。
- 静态资源、路由、重定向、缓存刷新状态有证据。
- CDN 或托管平台仍在传播时，报告传播状态，不提前写完成。
- 生产域名切流、别名绑定、缓存 purge 属于发布动作；没有明确授权不得执行。

### Internal web deployment

可用证据源：GitLab、Jenkins、镜像仓库、Helm、k8s、Rancher、Ingress、OTel、ES、Jaeger、内部监控与告警平台。

检查项：

- CI/CD job 指向当前 commit、镜像 tag 或 chart version。
- 镜像构建与推送成功，digest 或 tag 可追溯。
- Helm release、k8s Deployment、Rancher workload 已滚动到目标版本。
- Pod 状态为 Ready；重启次数、CrashLoop、ImagePullBackOff、探针失败需记录。
- Service、Ingress 或网关路由指向目标 workload。
- 内网访问验证来自允许的网络或平台探针；无权限时写明缺口。
- 内网生产发布、扩缩容、回滚、配置变更必须有明确授权。

## Phase 5: Post-deploy observability

- 日志：查询当前版本、请求路径、错误日志、启动日志。
- 指标：查看流量、错误率、延迟、资源使用、实例健康。
- Trace：确认 OTel trace 到达后端或前端采集链路；可用 Jaeger 等平台取证。
- 搜索：可用 ES 或日志平台按 trace id、request id、commit、pod、service 查询。
- 告警：确认没有新告警，或列出仍在 firing、pending、silenced 的告警。
- 合成探测：如平台有 synthetic check、健康检查或 smoke test，记录结果。
- 缺权限时报告“未验证”，并列出需要谁补充哪类证据。

## Failure triage

- 先取一手失败证据：失败 job、stage、命令、exit code、第一条真实错误、log、artifact、runner 信息。
- 区分失败类型：代码、依赖、测试、构建、镜像、部署、平台权限、环境资源、网络或监控链路。
- 不把 AI 猜测、控制台红叉、同事转述当根因。
- 对可复现失败，先在最小命令复现，再改代码或配置。
- 对权限失败，记录缺少的角色、平台、资源和最小可验证动作。
- 对间歇失败，记录重试次数、失败分布、runner 或节点信息。

## Rollback decision

- 触发条件：生产错误率上升、核心路径不可用、部署失败卡在半量、告警触发、数据或安全风险。
- 回滚前确认授权；生产回滚也是生产动作。
- 公网回滚证据：平台上一个成功部署、别名回切、CDN purge、回滚后的访问验证。
- 内网回滚证据：上一个镜像 tag、Helm revision、k8s rollout undo、Rancher workload 版本、回滚后的 pod 与 Ingress 验证。
- 回滚后仍需监控证据；不能只报告“已回滚”。

## Report format

```text
本地验证：
- 已运行：<命令 + 结果>
- 未运行：<原因>

CI/CD：
- 平台/流水线：<链接或名称>
- 状态：<通过/失败/等待/无权限>
- 失败证据：<job/stage/命令/exit code/第一条真实错误/artifact/runner>

部署路径：
- 类型：<公网/内网/未部署>
- 目标环境：<预览/测试/预发/生产>
- 证据：<部署记录/commit/镜像 tag/Helm release/k8s rollout/URL>

发布状态：
- 状态：<未发布/已部署到非生产/生产待授权/生产已授权并执行>
- 授权：<授权人和原话摘要；无则写无>

监控证据：
- 日志：<查询结果或无权限>
- 指标：<错误率/延迟/健康状态或无权限>
- Trace：<trace id/链路结果或无权限>
- 告警：<无新增/仍触发/无权限>

缺失权限/未验证项：
- <平台/资源/需要的最小权限/影响>
```

## 可复用 Prompt

```text
请按 Web delivery lifecycle runbook 交付这个 Web 项目：先检查项目脚本和部署入口；默认不启动 dev server；完成本地 lint/typecheck/test/build 中适用项；推送后观察 CI/CD 并读取失败 job、stage、命令、exit code、第一条真实错误、artifact 和 runner 信息；按公网或内网路径收集部署证据；生产合并、生产部署、生产发布必须等我明确授权；最后用报告格式区分本地验证、CI/CD、部署路径、发布状态、监控证据、缺失权限和未验证项。
```
