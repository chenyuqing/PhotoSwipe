//
//  PhotoService.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

@Observable
class PhotoService {
    var photos: [PhotoModel] = []
    var isLoading = false
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    @MainActor
    func requestPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }
    
    @MainActor
    func loadPhotos() async {
        isLoading = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        
        var newPhotos: [PhotoModel] = []
        
        assets.enumerateObjects { asset, _, _ in
            let photoModel = PhotoModel(asset: asset)
            
            // 检查历史记录并恢复状态
            let identifier = asset.localIdentifier
            if HistoryManager.shared.isPhotoDeleted(identifier) {
                photoModel.isMarkedForDeletion = true
            } else if HistoryManager.shared.isPhotoKept(identifier) {
                photoModel.isKept = true
            }
            
            newPhotos.append(photoModel)
        }
        
        photos = newPhotos
        isLoading = false
    }
}