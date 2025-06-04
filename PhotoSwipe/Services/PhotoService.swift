//
//  PhotoService.swift
//  PhotoSwipe
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import Photos
import UIKit

/// 照片服务类，负责相册访问和照片管理
@MainActor
class PhotoService: ObservableObject {
    
    /// 请求相册访问权限
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        @unknown default:
            return false
        }
    }
    
    /// 获取所有照片
    func fetchAllPhotos() async -> [PhotoModel] {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photos: [PhotoModel] = []
            
            assets.enumerateObjects { asset, _, _ in
                let photo = PhotoModel(asset: asset)
                photos.append(photo)
            }
            
            continuation.resume(returning: photos)
        }
    }
    
    /// 加载照片图像
    func loadImage(for photo: PhotoModel, targetSize: CGSize = CGSize(width: 300, height: 400)) async {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            imageManager.requestImage(
                for: photo.asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                DispatchQueue.main.async {
                    photo.image = image
                    continuation.resume()
                }
            }
        }
    }
    
    /// 批量删除照片
    func deletePhotos(_ photos: [PhotoModel]) async -> Bool {
        let assets = photos.map { $0.asset }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }) { success, error in
                if let error = error {
                    print("删除照片失败: \(error.localizedDescription)")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    /// 检查相册访问权限状态
    func checkPermissionStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
}
