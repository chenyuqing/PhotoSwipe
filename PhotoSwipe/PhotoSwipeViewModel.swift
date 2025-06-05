//
//  PhotoSwipeViewModel.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

@MainActor
class PhotoSwipeViewModel: ObservableObject {
    @Published var photoService = PhotoService()
    @Published var currentPhotoIndex = 0
    @Published var isLoading = false
    @Published var isDeleting = false
    
    var currentPhoto: PhotoModel? {
        guard currentPhotoIndex < photoService.photos.count else { return nil }
        return photoService.photos[currentPhotoIndex]
    }
    
    var markedPhotosCount: Int {
        photoService.photos.filter { $0.isMarkedForDeletion }.count
    }
    
    init() {
        // 恢复上次的浏览位置
        let (savedIndex, savedTotalCount) = HistoryManager.shared.getSavedPosition()
        if savedTotalCount > 0 {
            currentPhotoIndex = min(savedIndex, savedTotalCount - 1)
        }
    }
    
    func loadPhotos() async {
        isLoading = true
        await photoService.loadPhotos()
        
        // 确保索引在有效范围内
        if currentPhotoIndex >= photoService.photos.count {
            currentPhotoIndex = max(0, photoService.photos.count - 1)
        }
        
        // 应用历史标记
        applyHistoryMarks()
        
        isLoading = false
    }
    
    private func applyHistoryMarks() {
        let markedPhotos = HistoryManager.shared.getMarkedPhotos()
        let keptPhotos = HistoryManager.shared.getKeptPhotos()
        
        for photo in photoService.photos {
            if markedPhotos.contains(photo.asset.localIdentifier) {
                photo.isMarkedForDeletion = true
            }
            if keptPhotos.contains(photo.asset.localIdentifier) {
                photo.isKept = true
            }
        }
    }
    
    func moveToNextPhoto() {
        guard !photoService.photos.isEmpty else { return }
        
        // 保存当前位置
        HistoryManager.shared.saveCurrentPosition(currentPhotoIndex, totalCount: photoService.photos.count)
        
        if currentPhotoIndex < photoService.photos.count - 1 {
            currentPhotoIndex += 1
        } else {
            // 到达最后一张，可以选择循环或停留
            currentPhotoIndex = 0
        }
    }
    
    func moveToPreviousPhoto() {
        guard !photoService.photos.isEmpty else { return }
        
        if currentPhotoIndex > 0 {
            currentPhotoIndex -= 1
        } else {
            currentPhotoIndex = photoService.photos.count - 1
        }
        
        // 保存当前位置
        HistoryManager.shared.saveCurrentPosition(currentPhotoIndex, totalCount: photoService.photos.count)
    }
    
    func markCurrentPhotoForDeletion() {
        guard let photo = currentPhoto else { return }
        photo.isMarkedForDeletion = true
        photo.isKept = false // 取消保留状态
        
        // 保存到历史记录
        HistoryManager.shared.saveMarkedPhoto(photo.asset.localIdentifier)
        // 从保留记录中移除
        HistoryManager.shared.removeKeptPhoto(photo.asset.localIdentifier)
    }
    
    func keepCurrentPhoto() {
        guard let photo = currentPhoto else { return }
        photo.isKept = true
        photo.isMarkedForDeletion = false // 取消删除标记
        
        // 保存到保留记录
        HistoryManager.shared.saveKeptPhoto(photo.asset.localIdentifier)
        // 从删除标记中移除
        HistoryManager.shared.removeMarkForDeletion(photoId: photo.asset.localIdentifier)
    }
    
    func toggleCurrentPhotoMark() {
        guard let photo = currentPhoto else { return }
        
        if photo.isMarkedForDeletion {
            photo.isMarkedForDeletion = false
            HistoryManager.shared.removeMarkForDeletion(photoId: photo.asset.localIdentifier)
        } else {
            photo.isMarkedForDeletion = true
            photo.isKept = false
            HistoryManager.shared.saveMarkedPhoto(photo.asset.localIdentifier)
            HistoryManager.shared.removeKeptPhoto(photo.asset.localIdentifier)
        }
    }
    
    func unmarkCurrentPhoto() {
        guard let photo = currentPhoto else { return }
        photo.isMarkedForDeletion = false
        HistoryManager.shared.removeMarkForDeletion(photoId: photo.asset.localIdentifier)
    }
    
    func getCurrentPhotoInfo() -> String {
        guard let photo = currentPhoto else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var info = ""
        if let creationDate = photo.asset.creationDate {
            info += "拍摄时间: \(formatter.string(from: creationDate))\n"
        }
        
        let size = CGSize(width: photo.asset.pixelWidth, height: photo.asset.pixelHeight)
        info += "尺寸: \(Int(size.width)) × \(Int(size.height))\n"
        
        if let location = photo.asset.location {
            info += "位置: \(location.coordinate.latitude), \(location.coordinate.longitude)\n"
        }
        
        return info
    }
    
    func jumpToPhoto(at index: Int) {
        guard index >= 0 && index < photoService.photos.count else { return }
        currentPhotoIndex = index
        
        // 保存当前位置
        HistoryManager.shared.saveCurrentPosition(currentPhotoIndex, totalCount: photoService.photos.count)
    }
    
    func getPhotoProgress() -> Float {
        guard !photoService.photos.isEmpty else { return 0 }
        return Float(currentPhotoIndex + 1) / Float(photoService.photos.count)
    }
    
    func hasNextPhoto() -> Bool {
        return currentPhotoIndex < photoService.photos.count - 1
    }
    
    func hasPreviousPhoto() -> Bool {
        return currentPhotoIndex > 0
    }
    
    
    
    @MainActor
    func deleteMarkedPhotos() async {
        isDeleting = true
        await photoService.deleteMarkedPhotos()
        // 重置当前索引如果超出范围
        if currentPhotoIndex >= photoService.photos.count {
            currentPhotoIndex = max(0, photoService.photos.count - 1)
        }
        isDeleting = false
    }
    
    /// 删除指定的照片列表
    func deleteSpecificPhotos(_ photosToDelete: [PhotoModel]) async {
        isDeleting = true
        
        // 收集要删除的照片标识符
        let photoIdentifiers = photosToDelete.map { $0.asset.localIdentifier }
        
        // 从照片服务中删除
        await photoService.deleteSpecificPhotos(photosToDelete)
        
        // 保存到删除历史
        HistoryManager.shared.saveDeletedPhotos(photoIdentifiers)
        
        // 重置当前索引如果超出范围
        if currentPhotoIndex >= photoService.photos.count {
            currentPhotoIndex = max(0, photoService.photos.count - 1)
        }
        
        isDeleting = false
    }
    
    /// 获取统计信息
    func getStats() -> (total: Int, marked: Int, kept: Int, remaining: Int) {
        let total = photoService.photos.count
        let marked = photoService.photos.filter { $0.isMarkedForDeletion }.count
        let kept = photoService.photos.filter { $0.isKept }.count
        let remaining = total - marked - kept
        
        return (total: total, marked: marked, kept: kept, remaining: remaining)
    }
    
    /// 重置所有标记
    func resetAllMarks() {
        for photo in photoService.photos {
            photo.isMarkedForDeletion = false
            photo.isKept = false
        }
        HistoryManager.shared.clearAllRecords()
    }
    
    /// 获取当前照片的详细信息
    func getCurrentPhotoDetails() -> PhotoDetails? {
        guard let photo = currentPhoto else { return nil }
        
        return PhotoDetails(
            asset: photo.asset,
            isMarked: photo.isMarkedForDeletion,
            isKept: photo.isKept,
            index: currentPhotoIndex,
            total: photoService.photos.count
        )
    }
    
    /// 批量标记照片
    func markPhotos(_ photoIdentifiers: [String], forDeletion: Bool) {
        for identifier in photoIdentifiers {
            if let photo = photoService.photos.first(where: { $0.asset.localIdentifier == identifier }) {
                if forDeletion {
                    photo.isMarkedForDeletion = true
                    photo.isKept = false
                    HistoryManager.shared.saveMarkedPhoto(identifier)
                    HistoryManager.shared.removeKeptPhoto(identifier)
                } else {
                    photo.isKept = true
                    photo.isMarkedForDeletion = false
                    HistoryManager.shared.saveKeptPhoto(identifier)
                    HistoryManager.shared.removeMarkForDeletion(photoId: identifier)
                }
            }
        }
    }
}

/// 照片详细信息结构
struct PhotoDetails {
    let asset: PHAsset
    let isMarked: Bool
    let isKept: Bool
    let index: Int
    let total: Int
    
    var creationDate: Date? {
        asset.creationDate
    }
    
    var location: CLLocation? {
        asset.location
    }
    
    var dimensions: CGSize {
        CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    }
    
    var mediaType: PHAssetMediaType {
        asset.mediaType
    }
    
    var duration: TimeInterval {
        asset.duration
    }
}
