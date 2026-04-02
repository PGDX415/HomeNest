//
//  ImageManager.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation
import UIKit
import SwiftUI

/// 图片管理器 - 处理图片压缩、缓存和优化显示
class ImageManager {
    static let shared = ImageManager()
    
    // 内存缓存，使用NSCache自动管理内存压力
    private let imageCache = NSCache<NSString, UIImage>()
    
    // 配置参数
    private let maxImageWidth: CGFloat = 800
    private let maxImageHeight: CGFloat = 800
    private let compressionQuality: CGFloat = 0.8
    
    private init() {
        // 设置缓存限制
        imageCache.countLimit = 50 // 最多缓存50张图片
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 最多50MB
    }
    
    /// 压缩图片到指定尺寸和质量
    /// - Parameters:
    ///   - image: 原始UIImage
    ///   - maxWidth: 最大宽度（默认800）
    ///   - maxHeight: 最大高度（默认800）
    ///   - quality: 压缩质量（0.0-1.0，默认0.8）
    /// - Returns: 压缩后的Data，如果失败返回nil
    func compressImage(_ image: UIImage, maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil, quality: CGFloat? = nil) -> Data? {
        let finalMaxWidth = maxWidth ?? self.maxImageWidth
        let finalMaxHeight = maxHeight ?? self.maxImageHeight
        let finalQuality = quality ?? self.compressionQuality
        
        // 如果图片已经在尺寸范围内，直接压缩
        if image.size.width <= finalMaxWidth && image.size.height <= finalMaxHeight {
            return image.jpegData(compressionQuality: finalQuality)
        }
        
        // 计算缩放比例
        let scale = min(finalMaxWidth / image.size.width, finalMaxHeight / image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        // 创建缩放后的图片
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: finalQuality)
    }
    
    /// 从Data创建优化的UIImage（带缓存）
    /// - Parameters:
    ///   - data: 图片Data
    ///   - cacheKey: 缓存键（通常使用persistentModelID）
    /// - Returns: UIImage或nil
    func imageFromData(_ data: Data, cacheKey: String) -> UIImage? {
        // 检查缓存
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 创建图片
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        // 缓存图片
        imageCache.setObject(image, forKey: cacheKey as NSString)
        return image
    }
    
    /// 清除缓存
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    /// 获取缓存中的图片（不创建新图片）
    /// - Parameter cacheKey: 缓存键
    /// - Returns: 缓存的UIImage或nil
    func getCachedImage(_ cacheKey: String) -> UIImage? {
        return imageCache.object(forKey: cacheKey as NSString)
    }
}

/// SwiftUI视图扩展 - 安全的图片显示
struct CachedAsyncImage: View {
    let imageData: Data?
    let cacheKey: String
    let contentMode: ContentMode
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    
    @State private var image: UIImage?
    
    init(
        imageData: Data?,
        cacheKey: String,
        contentMode: ContentMode = .fit,
        maxWidth: CGFloat = .infinity,
        maxHeight: CGFloat = 300
    ) {
        self.imageData = imageData
        self.cacheKey = cacheKey
        self.contentMode = contentMode
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            } else {
                // 加载占位符
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .cornerRadius(16)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imageData) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageData = imageData else {
            image = nil
            return
        }
        
        // 尝试从缓存获取
        if let cachedImage = ImageManager.shared.getCachedImage(cacheKey) {
            image = cachedImage
            return
        }
        
        // 异步加载图片（防止阻塞UI）
        DispatchQueue.global(qos: .userInitiated).async {
            if let loadedImage = ImageManager.shared.imageFromData(imageData, cacheKey: cacheKey) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }
    }
}