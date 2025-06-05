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
    var photoService = PhotoService()
    var currentPhotoIndex = 0
    var showingPermissionAlert = false
    var showingDeleteConfirmation = false
    
    var currentPhoto: PhotoModel? {
        guard !photoService.photos.isEmpty,
              currentPhotoIndex >= 0,
              currentPhotoIndex < photoService.photos.count else {
            return nil
        }
        return photoService.photos[currentPhotoIndex]
    }
    
    /// 获取标记删除的照片数量
    var markedPhotosCount: Int {
        return photoService.photos.filter { $0.isMarkedForDeletion }.count
    }
    
    /// 获取保留照片数量
    var keptPhotosCount: Int {
        return HistoryManager.shared.getKeptPhotos().count
    }
    
    /// 获取已处理照片数量（标记删除 + 保留）
    var processedPhotosCount: Int {
        return photoService.photos.filter { $0.isMarkedForDeletion || $0.isMarkedForKeeping }.count
    }
    
    init() {
        // 初始化时恢复上次浏览位置
        if let savedIndex = HistoryManager.shared.getCurrentPhotoIndex() {
            currentPhotoIndex = savedIndex
        }
    }
    
    @MainActor
    func requestPermissionAndLoadPhotos() async {
        let status = await photoService.requestPermission()
        
        switch status {
        case .authorized, .limited:
            await photoService.loadPhotos()
            
            // 加载完成后，移动到第一张未处理的照片
            moveToFirstUnprocessedPhoto()
            
            // 预加载当前照片
            if let currentPhoto = currentPhoto {
                await currentPhoto.loadThumbnail()
                await currentPhoto.loadImage()
            }
            
        case .denied, .restricted:
            showingPermissionAlert = true
            
        case .notDetermined:
            break
            
        @unknown default:
            break
        }
    }
    
    /// 移动到第一张未处理的照片（既未删除也未保留）
    private func moveToFirstUnprocessedPhoto() {
        guard !photoService.photos.isEmpty else { return }
        
        // 从当前位置开始查找第一张未处理的照片
        for i in currentPhotoIndex..<photoService.photos.count {
            let photo = photoService.photos[i]
            if !photo.isMarkedForDeletion && !photo.isMarkedForKeeping {
                currentPhotoIndex = i
                HistoryManager.shared.saveCurrentPhotoIndex(currentPhotoIndex)
                return
            }
        }
        
        // 如果从当前位置到末尾都没有未处理的照片，从头开始查找
        for i in 0..<currentPhotoIndex {
            let photo = photoService.photos[i]
            if !photo.isMarkedForDeletion && !photo.isMarkedForKeeping {
                currentPhotoIndex = i
                HistoryManager.shared.saveCurrentPhotoIndex(currentPhotoIndex)
                return
            }
        }
    }
    
    func swipeLeft() {
        // 左滑表示"保留"，标记为保留
        if let currentPhoto = currentPhoto {
            currentPhoto.isMarkedForKeeping = true
        }
        moveToNextPhoto()
    }
    
    func swipeRight() {
        // 右滑表示"删除"，标记为待删除
        if let currentPhoto = currentPhoto {
            currentPhoto.isMarkedForDeletion = true
        }
        moveToNextPhoto()
    }
    
    private func moveToNextPhoto() {
        guard !photoService.photos.isEmpty else { return }
        
        // 直接移动到下一张照片，不跳过任何照片
        currentPhotoIndex = (currentPhotoIndex + 1) % photoService.photos.count
        
        // 保存当前位置
        HistoryManager.shared.saveCurrentPhotoIndex(currentPhotoIndex)
        
        // 预加载新的当前照片
        if let newCurrentPhoto = currentPhoto {
            Task {
                await newCurrentPhoto.loadThumbnail()
                await newCurrentPhoto.loadImage()
            }
        }
    }
    
    func moveToPreviousPhoto() {
        guard !photoService.photos.isEmpty else { return }
        
        // 直接移动到上一张照片，不跳过任何照片
        currentPhotoIndex = currentPhotoIndex > 0 ? currentPhotoIndex - 1 : photoService.photos.count - 1
        
        // 保存当前位置
        HistoryManager.shared.saveCurrentPhotoIndex(currentPhotoIndex)
        
        // 预加载新的当前照片
        if let newCurrentPhoto = currentPhoto {
            Task {
                await newCurrentPhoto.loadThumbnail()
                await newCurrentPhoto.loadImage()
            }
        }
    }
    
    @MainActor
    func deleteMarkedPhotos() async {
        let markedPhotos = photoService.photos.filter { $0.isMarkedForDeletion }
        
        guard !markedPhotos.isEmpty else { return }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let assetsToDelete = markedPhotos.map { $0.asset }
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
            }
            
            // 删除成功后，从本地数组中移除这些照片
            photoService.photos.removeAll { photo in
                markedPhotos.contains { $0.id == photo.id }
            }
            
            // 清除历史记录中对应的标记
            for photo in markedPhotos {
                HistoryManager.shared.removeMarkedPhoto(photo.asset.localIdentifier)
                HistoryManager.shared.addDeletedPhoto(photo.asset.localIdentifier)
            }
            
            // 调整当前照片索引
            if currentPhotoIndex >= photoService.photos.count {
                currentPhotoIndex = max(0, photoService.photos.count - 1)
            }
            
            // 移动到第一张未处理的照片
            moveToFirstUnprocessedPhoto()
            
        } catch {
            print("删除照片失败: \(error)")
        }
    }
    
    func confirmDeleteMarkedPhotos() {
        showingDeleteConfirmation = true
    }
    
    /// 获取扩展的历史统计信息
    func getExtendedHistoryStats() -> (markedCount: Int, deletedCount: Int, keptCount: Int) {
        return HistoryManager.shared.getExtendedHistoryStats()
    }
    
    /// 清除所有历史记录
    func clearAllHistory() {
        HistoryManager.shared.clearAllHistory()
        
        // 重新加载照片状态
        Task {
            await requestPermissionAndLoadPhotos()
        }
    }
    
    /// 清除所有记录（包括保留记录和位置）
    func clearAllRecords() {
        HistoryManager.shared.clearAllRecords()
    }
    
    /// 检查是否有历史记录
    func hasHistory() -> Bool {
        let stats = HistoryManager.shared.getExtendedHistoryStats()
        return stats.markedCount > 0 || stats.deletedCount > 0 || stats.keptCount > 0
    }
    
    /// 获取保留的照片列表
    func getKeptPhotos() -> [PhotoModel] {
        return photoService.photos.filter { $0.isMarkedForKeeping }
    }
    
    /// 重置照片的保留标记
    func resetPhotoKeepingMark(_ photo: PhotoModel) {
        photo.isMarkedForKeeping = false
    }
    
    /// 批量重置照片的保留标记
    func resetPhotosKeepingMark(_ photos: [PhotoModel]) {
        for photo in photos {
            photo.isMarkedForKeeping = false
        }
    }
    
    /// 获取标记删除的照片列表
    func getMarkedPhotos() -> [PhotoModel] {
        return photoService.photos.filter { $0.isMarkedForDeletion }
    }
    
    /// 重置照片的删除标记
    func resetPhotoMark(_ photo: PhotoModel) {
        photo.isMarkedForDeletion = false
    }
    
    /// 批量重置照片的删除标记
    func resetPhotosMark(_ photos: [PhotoModel]) {
        for photo in photos {
            photo.isMarkedForDeletion = false
        }
    }
    
    /// 将照片标记为保留（从删除状态转换）
    func markPhotoAsKept(_ photo: PhotoModel) {
        photo.isMarkedForDeletion = false
        photo.isMarkedForKeeping = true
    }
    
    /// 批量将照片标记为保留
    func markPhotosAsKept(_ photos: [PhotoModel]) {
        for photo in photos {
            photo.isMarkedForDeletion = false
            photo.isMarkedForKeeping = true
        }
    }
}
