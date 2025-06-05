//
//  PhotoModel.swift
//  PhotoSwipe
//
//  Created by Tim Chen on 2024/12/30.
//

import SwiftUI
import Photos

@Observable
class PhotoModel {
    let asset: PHAsset
    var image: UIImage?
    var thumbnail: UIImage?
    
    // 与HistoryManager相关的标记状态
    var isMarked: Bool {
        get {
            HistoryManager.shared.isMarked(asset.localIdentifier)
        }
        set {
            if newValue {
                HistoryManager.shared.markPhoto(asset.localIdentifier)
            } else {
                HistoryManager.shared.unmarkPhoto(asset.localIdentifier)
            }
        }
    }
    
    var isKept: Bool {
        get {
            HistoryManager.shared.isKept(asset.localIdentifier)
        }
        set {
            if newValue {
                HistoryManager.shared.keepPhoto(asset.localIdentifier)
            } else {
                HistoryManager.shared.removeKeptPhoto(asset.localIdentifier)
            }
        }
    }
    
    private let photoService: PhotoService?
    
    init(asset: PHAsset, photoService: PhotoService? = nil) {
        self.asset = asset
        self.photoService = photoService
    }
    
    /// 加载缩略图（快速显示）
    func loadThumbnail() async {
        // 先检查缓存
        let cacheKey = "thumb_\(asset.localIdentifier)"
        if let cachedImage = photoService?.getCachedImage(for: cacheKey) {
            await MainActor.run {
                self.thumbnail = cachedImage
            }
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false // 缩略图不允许网络访问，提高速度
        options.isSynchronous = false
        
        // 针对Live Photos优化：明确请求静态图片
        if asset.mediaSubtypes.contains(.photoLive) {
            // 对于Live Photos，设置特殊选项避免运动模糊
            options.version = .current // 获取当前编辑版本
            options.deliveryMode = .opportunistic // 先快速返回低质量，再返回高质量
        }
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200), // 小尺寸缩略图
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                Task { @MainActor in
                    if let image = image {
                        self?.thumbnail = image
                        // 缓存缩略图
                        self?.photoService?.cacheImage(image, for: cacheKey)
                    }
                    
                    // 防止多次resume continuation
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// 加载高质量图片（用于显示）
    func loadImage() async {
        // 先检查缓存
        let cacheKey = "full_\(asset.localIdentifier)"
        if let cachedImage = photoService?.getCachedImage(for: cacheKey) {
            await MainActor.run {
                self.image = cachedImage
            }
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        // 针对Live Photos优化：明确请求静态图片
        if asset.mediaSubtypes.contains(.photoLive) {
            // 对于Live Photos，设置特殊选项避免运动模糊
            options.version = .current // 获取当前编辑版本
            options.deliveryMode = .opportunistic // 先快速返回低质量，再返回高质量
        }
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 1200), // 适中尺寸，平衡质量和性能
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                Task { @MainActor in
                    if let image = image {
                        self?.image = image
                        // 缓存高质量图片
                        self?.photoService?.cacheImage(image, for: cacheKey)
                    }
                    
                    // 防止多次resume continuation
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// 获取显示用的图片（优先使用高质量，回退到缩略图）
    var displayImage: UIImage? {
        return image ?? thumbnail
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(asset.localIdentifier)
    }
    
    static func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
        return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}
