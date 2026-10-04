# 交付验证记录

日期：2026-10-04 UTC。环境：Linux x86_64。

## 已执行并通过

- 9 项 Python 静态/参考检查：完整源码引用、Xcode object ID 引用闭合、scheme XML、Info.plist 与隐私清单、图标和资源结构、禁止自动化/脚本注入特征、提醒取消失效保护的代码存在性、原生测试源文件存在性、手动云构建的静态约束，以及 JSON 夹具期望
- 12 个离线人工核对 JSON 案例由独立 Python 参考逻辑检查：一致、刚好预算、超一分钱、未知总额、错误/未知数量、容量不同、未知币种、不完整费用、未确认一次性付款、无预算、金额精度不明
- 独立源码人工复核；发现并修复缺失 Combine import、提醒设置与取消并发、页面时间过期后按钮状态不刷新问题；按实际待提醒时间安排一次本地状态刷新，避免触发后残留旧状态
- 两个预置官网入口经公开网页读取核查；无实际账户登录、购物车或支付操作

原始静态检查输出：[static-check-results.txt](static-check-results.txt)。这些检查**没有解析、编译或执行 Swift**，Python 的参考逻辑通过不能证明 Swift 实现运行正确。

## 已提供，但尚未执行

- GitHub 托管 Mac 的手动构建工作流（单 job、5 分钟、artifact 1 天）；源码交付阶段未启动、未生成云构建 IPA；后续发布/构建以仓库记录为准

- 17 个 XCTest 测试方法，覆盖金额、倒计时、配置、预算、数量、提醒策略、时区、Codable、入口白名单及共享离线夹具；不覆盖通知服务异步竞态或 SwiftUI 生命周期，这些仍需原生验收
- 原生 SwiftUI 编译与模拟器构建脚本
- 模拟器/真机手工验收清单

## 构建尝试：工具缺失，未开始编译

- `bash Scripts/test_core.sh`：退出码 2，当前没有 `swift`。见 [native-test-attempt.txt](native-test-attempt.txt)
- `bash Scripts/build_simulator.sh`：退出码 2，当前没有 `xcodebuild`。见 [simulator-build-attempt.txt](simulator-build-attempt.txt)

因此没有声称 Swift 编译通过、XCTest 通过、模拟器运行通过、真机可安装、通知实际投递、签名有效或 App Store 验证通过。没有生成 IPA。

## 下一道验收门槛

在安装完整 Xcode 的 Mac 上：先运行 `Scripts/test_core.sh`，再构建/运行应用，完成 [MANUAL_QA.md](MANUAL_QA.md)，最后由用户配置有效签名并验证真机。发现任何编译或系统行为问题后应修复并重跑相关检查。
