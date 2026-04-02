//
//  ProfileView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHomes: [Home]
    @Query private var userProfiles: [UserProfile]
    
    // 应用版本信息
    @State private var appVersion: String = ""
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            // 用户信息区域
            Section("我的信息") {
                Button(action: {
                    showingEditSheet = true
                }) {
                    HStack {
                        if let userProfile = userProfiles.first {
                            if let avatarData = userProfile.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                                .clipShape(Circle())
                        }
                        VStack(alignment: .leading) {
                            Text(userProfiles.first?.displayName ?? "HomeNest 用户")
                                .font(.headline)
                            Text("家庭物品管理专家")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 统计信息
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(allHomes.count) 个场所")
                            .font(.subheadline)
                        Text("\(getTotalItemCount()) 件物品")
                            .font(.subheadline)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            // 应用功能区域
            Section("应用功能") {
                NavigationLink(destination: UsageGuideView()) {
                    Label("使用说明", systemImage: "questionmark.circle")
                }
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("隐私政策", systemImage: "lock.shield")
                }
                NavigationLink(destination: TermsOfServiceView()) {
                    Label("用户协议", systemImage: "doc.text")
                }
            }
            
            // 关于区域
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(appVersion.isEmpty ? "获取中..." : appVersion)
                        .foregroundColor(.secondary)
                }
                NavigationLink(destination: AboutAppView()) {
                    Label("关于 HomeNest", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("我")
        .onAppear {
            loadAppVersion()
            ensureUserProfileExists()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditUserProfileView(userProfile: userProfiles.first)
        }
    }
    
    // 确保用户配置存在
    private func ensureUserProfileExists() {
        if userProfiles.isEmpty {
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
        }
    }
    
    // 获取总物品数量的辅助方法
    private func getTotalItemCount() -> Int {
        // 使用独立查询获取所有物品总数
        // 这样可以绕过可能存在的对象图导航问题
        let itemDescriptor = FetchDescriptor<Item>()
        do {
            let allItems = try modelContext.fetch(itemDescriptor)
            return allItems.count
        } catch {
            // 如果查询失败，回退到原有的对象图导航方法
            var totalCount = 0
            for home in allHomes {
                totalCount += home.totalItemCount()
            }
            return totalCount
        }
    }
    
    // 为特定home获取物品数量的辅助方法
    private func getItemCountForHome(_ home: Home) -> Int {
        // 首先尝试使用现有的totalItemCount方法（对于数据完整的情况）
        let directCount = home.totalItemCount()
        
        // 如果直接统计为0，但实际可能存在数据，使用独立查询验证
        if directCount == 0 {
            // 使用独立查询获取所有StorageLocation
            let locationDescriptor = FetchDescriptor<StorageLocation>()
            do {
                let allLocations = try modelContext.fetch(locationDescriptor)
                
                // 找到属于当前home的所有位置（包括间接子位置）
                var validLocations: [StorageLocation] = []
                for location in allLocations {
                    if isLocationInHome(location, targetHome: home) {
                        validLocations.append(location)
                    }
                }
                
                // 统计这些位置中的物品数量
                var itemCount = 0
                for location in validLocations {
                    itemCount += location.items.count
                }
                return itemCount
            } catch {
                // 如果独立查询失败，回退到直接统计
                return directCount
            }
        }
        
        return directCount
    }
    
    // 递归判断位置是否属于指定home
    private func isLocationInHome(_ location: StorageLocation, targetHome: Home) -> Bool {
        // 检查直接关联
        if location.home?.persistentModelID == targetHome.persistentModelID {
            return true
        }
        
        // 如果直接关联为空，沿父级链向上查找
        var currentLocation: StorageLocation? = location.parent
        var depth = 0
        let maxDepth = 10 // 防止无限循环
        
        while let current = currentLocation, depth < maxDepth {
            if current.home?.persistentModelID == targetHome.persistentModelID {
                return true
            }
            currentLocation = current.parent
            depth += 1
        }
        
        return false
    }
    
    // 加载应用版本信息
    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = "\(version) (\(build))"
        }
    }
}

// 编辑用户信息视图
struct EditUserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var userProfile: UserProfile?
    @State private var displayName: String = ""
    @State private var avatarImage: UIImage? = nil
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("头像") {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            if let avatarImage = avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else if let existingAvatar = userProfile?.avatarData,
                                      let uiImage = UIImage(data: existingAvatar) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Text("更改头像")
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section("基本信息") {
                    TextField("姓名", text: $displayName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("编辑个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                displayName = userProfile?.displayName ?? "HomeNest 用户"
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $avatarImage)
            }
        }
    }
    
    private func saveChanges() {
        guard let profile = userProfile else { return }
        
        // 更新显示名称
        profile.updateDisplayName(displayName)
        
        // 更新头像
        if let avatarImage = avatarImage {
            if let imageData = avatarImage.pngData() {
                profile.updateAvatar(imageData)
            }
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// 使用说明视图
struct UsageGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("使用说明")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("欢迎使用 HomeNest！")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Group {
                    Text("🏠 **场所管理**")
                        .font(.headline)
                    Text("• 点击底部「场所」标签开始管理\n• 添加您的家庭场所（如客厅、卧室、厨房等）\n• 每个场所可以包含多个存储位置")
                    
                    Text("📦 **位置管理**")
                        .font(.headline)
                    Text("• 在场所详情中添加存储位置\n• 位置可以嵌套（如衣柜→抽屉）\n• 支持多层级位置结构")
                    
                    Text("📋 **物品管理**")
                        .font(.headline)
                    Text("• 在位置详情中添加物品\n• 为物品设置分类、图标和颜色\n• 支持快速搜索和筛选")
                    
                    Text("📊 **数据统计**")
                        .font(.headline)
                    Text("• 查看整体物品分布统计\n• 了解各场所物品数量\n• 数据实时同步更新")
                }
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                
                Text("💡 **小贴士**")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("• 首次使用请先添加场所\n• 物品分类支持自定义\n• 所有数据本地安全存储\n• 支持iCloud云端同步（需开发者账户）")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("使用说明")
    }
}

// 隐私政策视图
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("生效日期：2026年4月2日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. 数据存储")
                        .font(.headline)
                    Text("HomeNest 采用本地优先的数据存储策略。所有您的家庭物品数据默认存储在您的设备本地，不会上传到任何服务器。")
                    
                    Text("2. iCloud 同步（可选）")
                        .font(.headline)
                    Text("如果您启用了 iCloud 同步功能，您的数据将在您授权的 Apple 设备间同步。此功能需要有效的 Apple Developer Program 订阅。")
                    
                    Text("3. 权限说明")
                        .font(.headline)
                    Text("• **生物识别权限**：用于敏感操作（如删除）的身份验证\n• **无网络权限**：基础功能无需网络连接\n• **无位置权限**：不收集您的地理位置信息")
                    
                    Text("4. 数据安全")
                        .font(.headline)
                    Text("我们采用 Apple 平台提供的安全机制保护您的数据。所有敏感操作都需要二次确认和生物识别验证。")
                    
                    Text("5. 第三方服务")
                        .font(.headline)
                    Text("本应用不集成任何第三方分析或广告 SDK，不会与任何第三方共享您的个人数据。")
                }
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                
                Text("联系我们")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("如有任何隐私相关问题，请联系开发者。")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("隐私政策")
    }
}

// 用户协议视图
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("用户协议")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("生效日期：2026年4月2日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. 服务范围")
                        .font(.headline)
                    Text("HomeNest 是一款家庭物品管理工具，帮助您整理和追踪家庭中的物品位置。")
                    
                    Text("2. 用户责任")
                        .font(.headline)
                    Text("• 您对输入的数据内容负责\n• 请定期备份重要数据\n• 不得用于非法用途")
                    
                    Text("3. 免责声明")
                        .font(.headline)
                    Text("• 本应用按「现状」提供，不保证无错误\n• 开发者不对数据丢失承担赔偿责任\n• 建议用户自行备份重要数据")
                    
                    Text("4. 知识产权")
                        .font(.headline)
                    Text("应用的所有权利归开发者所有。用户获得的是使用权，而非所有权。")
                    
                    Text("5. 协议修改")
                        .font(.headline)
                    Text("开发者保留随时修改本协议的权利。继续使用即表示您同意最新版本。")
                }
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .navigationTitle("用户协议")
    }
}

// 关于应用视图
struct AboutAppView: View {
    @State private var appVersion: String = ""
    
    var body: some View {
        List {
            Section("HomeNest") {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("HomeNest")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("家庭物品管理专家")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !appVersion.isEmpty {
                            Text("版本 \(appVersion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
            }
            
            Section("开发者") {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("Paul Dexin Gong")
                }
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("2026年")
                }
            }
            
            Section("技术栈") {
                Text("SwiftUI • SwiftData • CloudKit")
            }
            
            Section("开源声明") {
                Text("本应用遵循 Apple 开发者协议")
            }
        }
        .navigationTitle("关于")
        .onAppear {
            loadAppVersion()
        }
    }
    
    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(for: [Item.self, StorageLocation.self, Home.self, UserProfile.self], inMemory: true)
}