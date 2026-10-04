# 没有 Mac：GitHub 托管 Mac 构建

已为指定公开仓库 `wuyunqing2010/DuoAssistant` 准备 `.github/workflows/build-unsigned-ipa.yml`。源码发布不会自动启动构建；本地源码交付时没有执行该工作流，没有生成 IPA。后续实际状态以仓库 Actions 记录为准。

## 有界、手动的构建

- 仅 `workflow_dispatch`，没有 push / pull_request / schedule 自动触发
- 仅允许上述指定公开仓库，运行者须勾选一次运行确认
- 一个标准 `macos-15` 托管 runner job，最长5分钟，无并行矩阵、自动重试或 larger runner
- 最小 `contents: read` 权限，checkout 不保留凭据，不导入 Apple 账号、签名材料或新 token
- 先执行结构检查和 Swift Package 原生测试，再尝试 iPhone arm64 无签名构建
- 成功后打包 `Payload/PurchaseAssistant.app` 为 `PurchaseAssistant-unsigned.ipa`，生成校验值，artifact 保留1天
- 不发布 Release、不部署、不上传 App Store

5分钟是单次运行超时限制，不是成功保证。冷启动或首次编译可能超时；失败后需查看日志并另获允许才重跑。公开仓库的源码、运行日志和产物应按公开信息对待，不能放入账号、签名密钥、私人文件或其他秘密。

## 使用步骤

1. 确认目标为上述新仓库；不要改动其他项目
2. 解压目录内文件放仓库根目录，包含隐藏 `.github` 目录；不能只上传ZIP
3. workflow 文件需位于默认分支，仓库策略需允许 Actions；先核对实际提交 SHA
4. 取得这一次运行许可后，在 Actions 的相应 workflow 中勾选 confirm_run，仅启动一次
5. 成功后1天内下载 artifact；无签名 IPA 仍需由用户使用合规方法完成有效签名，才能在 iPhone 安装

工作流使用 GitHub 官方 `actions/checkout@v7` 和 `actions/upload-artifact@v7`；版本标签会更新，组织如要求固定版本，应核验官方发布后使用完整 commit SHA，不能臆造。runner 预装 Xcode 可能更新，实际版本会写入日志。

## 一次性运行授权示例

“允许在 wuyunqing2010/DuoAssistant 的指定提交上手动运行一次所附工作流：标准 macos-15，单任务最长5分钟，不自动重试，公开的未签名 IPA 产物保留1天。不上传签名材料、不发布 Release 或 App Store；如果需要新增付费服务，先停下问我。”

源码发布许可不等于已经启动构建；示例也不代表获得了本次运行许可。

## 官方依据（2026-10-04读取）

- [标准 runner](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)
- [工作流超时与语法](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [手动触发与默认分支要求](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
- [Actions 计费](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- [官方 checkout](https://github.com/actions/checkout)
- [官方 artifact action](https://github.com/actions/upload-artifact)

当前官方规则下，公开仓库使用标准 GitHub 托管 runner 免费；larger runner 仍收费。不要把这个结论推广到所有存储或账户服务。artifact 的1天保留不会修改仓库日志保留政策，也不会消除已有费用。
