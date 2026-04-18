import SwiftUI

struct SupportDeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("感谢您的支持！") {
                Text("HomeNest 是一款完全免费的家庭物品管理应用，没有任何广告或隐藏收费。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
                
                Text("如果您觉得这款应用对您有帮助，可以通过以下方式支持开发者：")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
            }
            
            Section("支持方式") {
                // 实际支付集成（需要企业资质）
                #if ENTERPRISE_MODE
                Button(action: {
                    startAlipayDonation()
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("支付宝捐赠")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.orange)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    startWeChatDonation()
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("微信捐赠")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
                #else
                // 网页捐赠链接（个人开发者友好方案）
                Link(destination: URL(string: "https://afdian.net/@your-username")!) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("爱发电支持")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                }
                
                Link(destination: URL(string: "https://your-wechat-sponsor-page.com")!) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("微信赞赏码")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.green)
                }
                #endif
                
                // 邮箱联系
                Link(destination: URL(string: "mailto:pgong415@outlook.com")!) {
                    Label("联系开发者", systemImage: "envelope.fill")
                }
                
                // App Store 评分
                Button(action: {
                    openAppStoreReview()
                }) {
                    Label("App Store 评分", systemImage: "star.fill")
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Section("您的支持将用于") {
                Text("• 应用持续开发和维护")
                    .font(.subheadline)
                Text("• 新功能开发")
                    .font(.subheadline)
                Text("• 服务器和开发工具费用")
                    .font(.subheadline)
                Text("• 让 HomeNest 变得更好！")
                    .font(.subheadline)
            }
        }
        .navigationTitle("支持开发者")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func openAppStoreReview() {
        // 打开 App Store 评分页面（需要替换为实际的 App ID）
        let appID = "YOUR_APP_ID_HERE" // TODO: 替换为您的实际 App ID
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    #if ENTERPRISE_MODE
    private func startAlipayDonation() {
        // TODO: 调用后端接口获取支付宝订单字符串
        // AlipayManager.shared.pay(orderString: orderString) { success, message in
        //     DispatchQueue.main.async {
        //         self.showAlert(message: message ?? "")
        //     }
        // }
    }
    
    private func startWeChatDonation() {
        // TODO: 调用后端接口获取微信支付请求参数
        // let req = PayReq()
        // req.partnerId = "your_partner_id"
        // req.prepayId = "your_prepay_id"
        // req.nonceStr = "your_nonce_str"
        // req.timeStamp = UInt32(Date().timeIntervalSince1970)
        // req.package = "Sign=WXPay"
        // req.sign = "your_sign"
        // 
        // WeChatPayManager.shared.pay(request: req) { success, message in
        //     DispatchQueue.main.async {
        //         self.showAlert(message: message ?? "")
        //     }
        // }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "支付结果", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.keyWindow?.rootViewController?.present(alert, animated: true)
            }
        } else {
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
    #endif
}

#Preview {
    SupportDeveloperView()
}
