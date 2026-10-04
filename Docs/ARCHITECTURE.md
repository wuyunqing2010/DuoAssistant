# 架构与安全边界

## 数据流

1. `PlanEditorView` 编辑草稿，取消不写入；保存后 `PlanStore` 更新 UserDefaults 和内存计划
2. 计划变更触发旧通知取消；`ManualReviewView` 的旧核对内容清空
3. `DashboardView` 使用 `TimelineView` 按设备当前时间刷新绝对目标时间的倒计时
4. 用户点击提醒设置后，`ReminderService` 请求通知权限，验证未来触发时间并安排单次系统通知
5. `OfficialBrowserCard` 只打开预设 HTTPS 官网页面，不建立内嵌 WebView，不向页面注入代码
6. 人工核对页接受用户抄录的值，交给 `ManualReviewPolicy` 做严格比较；它不触发任何网络或付款操作

## 核心原则

- 业务核心仅依赖 Foundation，可通过 Swift Package 单独测试
- 金额使用 Decimal；输入严格限制 8 位整数 + 最多 2 位小数，不静默舍入，不接受月供格式、货币符号或分组逗号
- 核对缺失、金额格式不明、预算缺失、数量不等于 1、配置不一致或任一事实未确认均返回问题清单
- 官网数据不可读，因为 App 根本不读取浏览器；UI 只称“填写值与计划一致”，从不称“订单验证成功”
- 浏览器由系统控制；初始 URL 白名单不代表能约束浏览器后续跳转或页面付款。此边界在 UI 和 README 明示
- 目标日期是 Date 绝对时刻；时区只影响编辑和显示。更换时区保持同一时刻，要求重新确认
- 提醒用 UTC Calendar components 固定瞬时，避免手机更换时区后改变目标瞬时；具体系统行为仍需真机验收
- 通知 identifier 固定，重复设置替换旧提醒；generation token 使取消可以作废正在等待授权/添加的旧操作
- 用户填写的核对数据仅在内存，不放进通知文案；计划字段可进入 iOS 系统备份，未承诺加密保险库能力

## 隐私清单

`PrivacyInfo.xcprivacy` 声明不跟踪、不收集数据，并为 App 本机偏好存储声明 UserDefaults 的 CA92.1 required reason。没有访问相机、麦克风、定位或通讯录的用途字段。上架前仍须由开发者针对实际最终代码复核 App Privacy、隐私政策和所有 Apple 要求。

参考：[Apple Required Reason API 文档](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)

## 不包含的实现

没有库存 API、账号管理、自动点击、WebKit 脚本、支付 SDK、验证码处理、反检测、多账户并发、自动重试下单或云端提醒。未来如果新增任何功能，需要新的测试与安全设计，而不是复用原来的核对说明。
