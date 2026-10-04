# 购机准备 · iOS 原生源码版

一个从零编写、便于维护的中文 iPhone 购机准备助手。最低运行目标 iOS 17，使用 SwiftUI、Foundation 与 UserNotifications，无第三方 SDK 或服务端。

**这次交付是完整源码工程，不是 IPA 安装包。当前 Linux 环境没有 Swift、Xcode 或 Apple SDK，尚未完成原生编译、XCTest 执行、模拟器运行和真机验证。** 具体检查结果见 [VERIFICATION.md](Docs/VERIFICATION.md)。

没有反编译、修改或运行旧 IPA；没有沿用旧 App 的未知脚本、商品信息或签名。原生代码与图标均为新建内容。

## 已实现的功能

- 中文原生三页界面：准备、人工核对、使用说明；支持系统浅色/深色、动态字体与基础辅助功能
- 自填型号、颜色、容量及人民币预算，固定购买数量为 1 台；本机保存计划
- 可编辑目标日期和时区，明确要求确认时间；初始日期是占位，不是官方开售时间
- 根据绝对时间计算倒计时，可设置目标时刻、提前 5 分钟或提前 15 分钟的一次性本地提醒
- 修改计划会取消旧提醒；重复设置替换原提醒；取消能使正在进行的旧设置失效
- 只在用户点击后打开系统默认浏览器中的 Apple 中国大陆官网；提供通用 iPhone 页和商店首页
- 人工抄录商品及最终总额，核对型号/颜色/容量/数量、币种、完整费用、一次性付款及预算；未知、不匹配或超预算时不给出“一致”结果
- 核对内容改变、计划改变或 App 离开前台后使结果失效；人工核对内容只保存在内存

## 重要边界

本 App 不会自动读取浏览器页面、查库存、刷新、加购、下单或付款，不会绕过验证码或排队，也不操作多账户。它不保证抢到。

“一致”仅表示**你输入的值**与本机计划一致，不表示官网数据已经验证、商品有货或订单已生成。预算不会限制浏览器交易。最终页面内容、价格、数量、配送、条款、提交与付款均需你在官网自行核对和操作。

App 不保存密码、Cookie、银行卡、收货地址或登录令牌。没有自建服务器和分析 SDK。计划保存在 App 的 UserDefaults，可能随 iOS 系统备份保存。浏览器中的账号与交易数据由浏览器和网站处理。

本工具与 Apple 无关联；不预设 “iPhone Duo” 是已发布或正在销售的产品。商品与销售时间请以官网为准。

## 没有 Mac 也可准备云端构建

已附只手动启动的 GitHub 托管 Mac 工作流，单任务最长 5 分钟，仅允许指定的公开仓库 wuyunqing2010/DuoAssistant，未签名 IPA 产物保留 1 天。工作流不会自动运行；取得一次运行许可后才手动启动，实际结果以 Actions 记录为准。详见 [没有 Mac 的构建方式](Docs/NO_MAC_BUILD.md)。这不能替代有效签名。GitHub 当前规则下公开仓库的标准 runner 运行免费；其他计费项目仍应核查。

## 先在 Mac 上编译

1. 安装适合你 macOS 版本的完整 Xcode，并完成首次启动、许可确认和 iOS Simulator runtime 安装
2. 解压后打开 `PurchaseAssistant.xcodeproj`，选择 `PurchaseAssistant` scheme
3. 先选择可用的 iPhone 模拟器，执行 Product → Run。模拟器构建不需要填写 Team 或购买开发者会员
4. 运行纯逻辑测试：在工程根目录终端执行 `bash Scripts/test_core.sh`，或在 Xcode 中单独打开 `Package.swift` 并运行 `PurchaseCore` 的测试
5. 按 [MANUAL_QA.md](Docs/MANUAL_QA.md) 完成界面、提醒、后台恢复、无效输入等验收，再考虑真机签名

完整应用与 Swift Package 共用 `Sources/PurchaseCore` 下的同一份核心代码；工程不依赖 XcodeGen 或远端包。应用 scheme 中没有 XCTest target，**不要把直接点击应用的 Test 当作已执行核心测试**，请使用上面的 Package 测试入口。

命令行模拟器构建：

```sh
bash Scripts/build_simulator.sh
```

此脚本调用系统安装的完整 Xcode，为通用 iOS Simulator destination 构建并关闭模拟器签名；不会自动安装 Xcode 或上传代码。

### 工具链版本

- 设计基线：iOS 17+、Swift tools 5.9、Xcode 15+；Xcode 15 的历史最低系统为 macOS Ventura 13.5。由于这里没有 Apple 工具链，该最低兼容性尚未实编验证
- 截至 2026-10-04，App Store Connect 上传要求 iOS 26 SDK 或更新（2026-04-28 生效）；Xcode 26 含 iOS 26 SDK，最低要求 macOS Sequoia 15.6。具体新版 Xcode 要求以 Apple 当前列表为准
- SDK 版本与最低运行版本不同：使用更新 SDK 时仍可将 Deployment Target 设为 iOS 17

官方参考：[Xcode 系统要求](https://developer.apple.com/xcode/system-requirements/)、[Xcode 15 说明](https://developer.apple.com/documentation/xcode-release-notes/xcode-15-release-notes)、[上传 SDK 要求](https://developer.apple.com/news/?id=ueeok6yw)

## 真机签名与 IPA

本工程故意没有 Team、证书或 provisioning profile。签名由你在自己的 Mac 上完成：

1. 在 Xcode 登录你的 Apple Account
2. 在 Signing & Capabilities 中，把示例 Bundle Identifier `com.example.PurchaseAssistant` 改成自己的唯一标识，选择你的 Team，并启用 Automatically manage signing
3. 连接并信任自己的 iPhone，按 Xcode 提示由你启用 Developer Mode，选择该设备并运行
4. 需要分发时，按你的开发者资格配置证书、设备和 provisioning profile，选择真机或 build-only destination → Product → Archive → Organizer → Distribute App
5. 按目的选择已注册设备测试或 TestFlight / App Store；导出选项和要求随 Xcode 与账号资格变化，不提供未经验证的固定 ExportOptions 文件

免费 Personal Team 可用于个人设备测试，通常需在 7 天 profile 到期后重新构建安装，且不等于拥有正式分发资格。**未签名的 .app 打包成 .ipa 也不能直接在 iPhone 上正常安装运行；模拟器产物不能作为真机包。** 本交付没有生成或伪造“可安装 IPA”。

官方参考：[运行到设备或模拟器](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)、[会员差异](https://developer.apple.com/support/compare-memberships/)、[注册设备分发](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)、[归档与分发](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)、[签名格式](https://developer.apple.com/documentation/xcode/using-the-latest-code-signature-format)

## 文件结构

```text
App/                         SwiftUI 界面、提醒与本机存储服务、资源
Sources/PurchaseCore/        可独立测试的预算、时间、核对及官网入口逻辑
Tests/PurchaseCoreTests/     17 个 XCTest 用例与 12 个离线核对夹具
PurchaseAssistant.xcodeproj 可直接打开的 Xcode 工程和共享 scheme
Package.swift               纯逻辑的 Swift Package 测试入口
Scripts/                    结构检查、工程再生成、原生测试与构建入口
.github/workflows/          待授权、只手动运行的托管 Mac 构建配置
Docs/                       验证记录、手工验收单、架构说明
```

## 开发和维护

- 改 UI：`App/Views`；改业务规则：`Sources/PurchaseCore`
- 新增/移除 App 或 Core 文件后，运行 `python3 Scripts/generate_project.py` 更新工程。该生成器会重建工程设置，因此自己的签名配置应在生成后重新设置；不会写入或管理证书
- 无 Swift 的环境可运行 `python3 Scripts/verify_source.py`。它只检查工程结构、资源和 JSON 夹具的独立参考期望，不解析或执行 Swift，也不是 iOS 构建测试
- 原生 XCTest 和模拟器构建均应在每次发布前实际运行；任何后续产品目录、网页读取或联网功能需单独设计和验证，不能把现在的人工抄录结果冒充实时官网验证

官网入口：[Apple 中国大陆 iPhone](https://www.apple.com.cn/iphone/)、[Apple 商店](https://www.apple.com.cn/store)。读取校验时间：2026-10-04。
