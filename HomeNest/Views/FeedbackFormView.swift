//
//  FeedbackFormView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI
import MessageUI

struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedbackType: FeedbackType = .general
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum FeedbackType: String, CaseIterable, Identifiable {
        case general = "一般反馈"
        case bug = "Bug报告"
        case feature = "功能建议"
        case question = "使用问题"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("反馈类型") {
                    Picker("类型", selection: $feedbackType) {
                        ForEach(FeedbackType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("联系信息（可选）") {
                    TextField("邮箱地址", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                
                Section("主题") {
                    TextField("请输入主题", text: $subject)
                }
                
                Section("详细描述") {
                    TextEditor(text: $message)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Section {
                    Button(action: submitFeedback) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("提交反馈")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(isSubmitting ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || subject.isEmpty || message.isEmpty)
                }
            }
            .navigationTitle("反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("提交结果", isPresented: $showAlert) {
                Button("确定") {
                    if alertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func submitFeedback() {
        guard !subject.isEmpty && !message.isEmpty else {
            showAlert = true
            alertMessage = "请填写主题和详细描述。"
            return
        }
        
        isSubmitting = true
        
        // 构建邮件内容
        let deviceInfo = """
        设备型号: \(UIDevice.current.model)
        系统版本: \(UIDevice.current.systemVersion)
        应用版本: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知")
        反馈类型: \(feedbackType.rawValue)
        """
        
        let fullMessage = """
        \(message)
        
        ---
        \(deviceInfo)
        """
        
        // 尝试发送邮件
        if MFMailComposeViewController.canSendMail() {
            sendEmail(subject: "[HomeNest反馈] \(subject)", body: fullMessage)
        } else {
            // 如果无法发送邮件，显示提示
            isSubmitting = false
            showAlert = true
            alertMessage = "您的设备未配置邮件账户。请通过其他方式联系我们，或在设置中配置邮件账户后重试。"
        }
    }
    
    private func sendEmail(subject: String, body: String) {
        // 这里需要实现邮件发送逻辑
        // 由于我们无法直接访问MFMailComposeViewController在SwiftUI中，
        // 我们将使用一个协调器模式
        isSubmitting = false
        showAlert = true
        alertMessage = "邮件功能暂未完全实现。请手动发送邮件至开发者邮箱，或等待后续版本更新。"
        
        // 实际实现需要创建一个UIViewControllerRepresentable来包装MFMailComposeViewController
        // 这将在后续完善
    }
}

#Preview {
    FeedbackFormView()
}