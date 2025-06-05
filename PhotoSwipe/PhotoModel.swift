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
    var isMarked: Bool = false
    var isKept: Bool = false
    
    private let photoService: PhotoService?
    
    init(asset: PHAsset, photoService: PhotoService? = nil) {
        self.asset = asset
        self.photoService = photoService
    }
    
    @MainActor
    func loadThumbnail() async {
        // 检查缓存
        let cacheKey = "thumb_\(asset.localIdentifier)"
        if let cachedImage = photoService?.getCachedImage(for: cacheKey) {
            self.thumbnail = cachedImage
            return
        }
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        // 针对Live Photos优化：明确请求静态图片
        if asset.mediaSubtypes.contains(.photoLive) {
            // 对于Live Photos，设置特殊选项避免运动模糊
            options.version = .current // 获取当前编辑版本
            options.deliveryMode = .opportunistic // 先快速返回低质量，再返回高质量
        }
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200), // 小尺寸缩略图
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                Task { @MainActor in
                    if let image = image {
                        self?.thumbnail = image
                        // 缓存缩略图
                        self?.photoService?.cacheImage(image, for: cacheKey)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    func loadImage() async {
        // 检查缓存
        let cacheKey = "full_\(asset.localIdentifier)"
        if let cachedImage = photoService?.getCachedImage(for: cacheKey) {
            self.image = cachedImage
            return
        }
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        // 针对Live Photos优化：明确请求静态图片
        if asset.mediaSubtypes.contains(.photoLive) {
            // 对于Live Photos，设置特殊选项避免运动模糊
            options.version = .current // 获取当前编辑版本
            options.deliveryMode = .opportunistic // 先快速返回低质量，再返回高质量
        }
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 1200), // 适中尺寸，平衡质量和性能
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                Task { @MainActor in
                    if let image = image {
                        self?.image = image
                        // 缓存高质量图片
                        self?.photoService?.cacheImage(image, for: cacheKey)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // 计算属性：优先返回高质量图片，回退到缩略图
    var displayImage: UIImage? {
        return image ?? thumbnail
    }
}
