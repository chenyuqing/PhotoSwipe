//
//  PhotoModel.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

@Observable
class PhotoModel: Identifiable {
    let id = UUID()
    let asset: PHAsset
    
    var thumbnail: UIImage?
    var image: UIImage?
    var isMarkedForDeletion = false
    var isKept = false
    
    // 用于显示的图片（优先使用高质量图片，否则使用缩略图）
    var displayImage: UIImage? {
        return image ?? thumbnail
    }
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    @MainActor
    func loadThumbnail() async {
        guard thumbnail == nil else { return }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        
        return await withCheckedContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                Task { @MainActor in
                    self?.thumbnail = image
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    func loadImage() async {
        guard image == nil else { return }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        return await withCheckedContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                Task { @MainActor in
                    self?.image = image
                    continuation.resume()
                }
            }
        }
    }
}