//
//  PhotoSwipeViewModel.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

@Observable
class PhotoSwipeViewModel {
    let photoService = PhotoService()
    
    var currentPhotoIndex = 0
    var showingDeleteAlert = false
    var showingPermissionAlert = false
    
    var currentPhoto: PhotoModel? {
        guard !photoService.photos.isEmpty,
              currentPhotoIndex < photoService.photos.count else {
            return nil
        }
        return photoService.photos[currentPhotoIndex]
    }
    
    var markedPhotos: [PhotoModel] {
        photoService.photos.filter { $0.isMarkedForDeletion }
    }
    
    var keptPhotos: [PhotoModel] {
        photoService.photos.filter { $0.isKept }
    }
    
    var markedPhotosCount: Int {
        markedPhotos.count
    }
    
    var keptPhotosCount: Int {
        keptPhotos.count
    }
    
    var processedPhotosCount: Int {
        markedPhotosCount + keptPhotosCount
    }
    
    init() {
        // 恢复保存的位置
        restoreSavedPosition()
    }
    
    @MainActor
    func requestPermissionAndLoadPhotos() async {
        let status = await photoService.requestPermission()
        
        switch status {
        case .authorized, .limited:
            await photoService.loadPhotos()
            // 加载完成后再次恢复位置（以防照片数量发生变化）
            restoreSavedPosition()
        case .denied, .restricted:
            showingPermissionAlert = true
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func swipeLeft() {
        guard let photo = currentPhoto else { return }
        
        // 标记为保留
        photo.isKept = true
        photo.isMarkedForDeletion = false
        
        // 记录到历史
        HistoryManager.shared.addKeptPhoto(photo.asset.localIdentifier)
        
        moveToNextPhoto()
    }
    
    func swipeRight() {
        guard let photo = currentPhoto else { return }
        
        // 标记为删除
        photo.isMarkedForDeletion = true
        photo.isKept = false
        
        // 记录到历史
        HistoryManager.shared.addDeletedPhoto(photo.asset.localIdentifier)
        
        moveToNextPhoto()
    }
    
    func resetCurrentPhotoMark() {
        guard let photo = currentPhoto else { return }
        
        // 清除标记
        photo.isMarkedForDeletion = false
        photo.isKept = false
        
        // 从历史记录中移除
        HistoryManager.shared.removeFromHistory(photo.asset.localIdentifier)
    }
    
    private func moveToNextPhoto() {
        if currentPhotoIndex < photoService.photos.count - 1 {
            currentPhotoIndex += 1
        } else {
            // 已经是最后一张，重新开始
            currentPhotoIndex = 0
        }
        
        // 保存当前位置
        saveCurrentPosition()
    }
    
    func showDeleteConfirmation() {
        showingDeleteAlert = true
    }
    
    @MainActor
    func deleteMarkedPhotos() async {
        let photosToDelete = markedPhotos.map { $0.asset }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(photosToDelete as NSArray)
            }
            
            // 删除成功后，从数组中移除这些照片
            photoService.photos.removeAll { photo in
                photosToDelete.contains(photo.asset)
            }
            
            // 调整当前索引
            if currentPhotoIndex >= photoService.photos.count {
                currentPhotoIndex = max(0, photoService.photos.count - 1)
            }
            
            // 保存位置
            saveCurrentPosition()
            
        } catch {
            print("删除照片失败: \(error)")
        }
    }
    
    func removeMarkFromPhoto(_ photo: PhotoModel) {
        photo.isMarkedForDeletion = false
        HistoryManager.shared.removeFromHistory(photo.asset.localIdentifier)
    }
    
    func removeKeepFromPhoto(_ photo: PhotoModel) {
        photo.isKept = false
        HistoryManager.shared.removeFromHistory(photo.asset.localIdentifier)
    }
    
    func clearAllMarks() {
        for photo in photoService.photos {
            photo.isMarkedForDeletion = false
            photo.isKept = false
        }
    }
    
    func clearAllRecords() {
        HistoryManager.shared.clearAllHistory()
    }
    
    func hasHistory() -> Bool {
        let stats = HistoryManager.shared.getHistoryStats()
        return stats.deletedCount > 0 || stats.keptCount > 0
    }
    
    func getExtendedHistoryStats() -> (deletedCount: Int, keptCount: Int) {
        let stats = HistoryManager.shared.getHistoryStats()
        return (deletedCount: stats.deletedCount, keptCount: stats.keptCount)
    }
    
    // MARK: - 位置保存和恢复
    
    private func saveCurrentPosition() {
        UserDefaults.standard.set(currentPhotoIndex, forKey: "currentPhotoIndex")
        UserDefaults.standard.set(photoService.photos.count, forKey: "totalPhotosCount")
    }
    
    private func restoreSavedPosition() {
        let savedIndex = UserDefaults.standard.integer(forKey: "currentPhotoIndex")
        
        // 只要索引有效就恢复，不再要求照片总数完全匹配
        if savedIndex >= 0 && savedIndex < photoService.photos.count {
            currentPhotoIndex = savedIndex
        } else {
            currentPhotoIndex = 0
        }
    }
}