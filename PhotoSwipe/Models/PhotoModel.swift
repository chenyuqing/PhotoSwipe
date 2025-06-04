//
//  PhotoModel.swift
//  PhotoSwipe
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import Photos
import UIKit

/// 照片模型，符合 Identifiable 和 Observable 协议
@Observable
class PhotoModel: Identifiable {
    let id = UUID()
    let asset: PHAsset
    var image: UIImage?
    var isMarkedForDeletion: Bool = false
    var swipeOffset: CGFloat = 0
    var rotation: Double = 0
    
    init(asset: PHAsset) {
        self.asset = asset
    }
}

/// 滑动方向枚举
enum SwipeDirection {
    case left   // 不喜欢
    case right  // 喜欢
    case none   // 无方向
}

/// 照片状态枚举
enum PhotoStatus {
    case normal
    case liked
    case disliked
    case markedForDeletion
}
