//
//  PhotoService.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import Foundation
import Photos
import UIKit

@Observable
class PhotoService {
    var photos: [PhotoModel] = []
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var isLoading: Bool = false
    var errorMessage: String?
    
    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    @MainActor
    func requestPhotoLibraryAccess() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        
        if status == .authorized || status == .limited {
            await loadPhotos()
        } else {
            errorMessage = "需要访问相册权限才能使用此功能"
        }
    }
    
    @MainActor
    private func loadPhotos() async {
        isLoading = true
        errorMessage = nil
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        
        var newPhotos: [PhotoModel] = []
        
        assets.enumerateObjects { asset, _, _ in
            let photoModel = PhotoModel(asset: asset)
            newPhotos.append(photoModel)
        }
        
        photos = newPhotos
        isLoading = false
        
        // 预加载前几张图片
        await loadInitialImages()
    }
    
    private func loadInitialImages() async {
        let imagesToLoad = min(5, photos.count)
        for i in 0..<imagesToLoad {
            await photos[i].loadImage()
        }
    }
    
    @MainActor
    func deleteMarkedPhotos() async {
        let photosToDelete = photos.filter { $0.isMarkedForDeletion }
        let assetsToDelete = photosToDelete.map { $0.asset }
        
        guard !assetsToDelete.isEmpty else { return }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
            }
            
            // 从本地数组中移除已删除的照片
            photos.removeAll { $0.isMarkedForDeletion }
            
        } catch {
            errorMessage = "删除照片失败: \(error.localizedDescription)"
        }
    }
    
    func getMarkedPhotosCount() -> Int {
        return photos.filter { $0.isMarkedForDeletion }.count
    }
}