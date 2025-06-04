//
//  PhotoViewModel.swift
//  PhotoSwipe
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import Photos
import SwiftUI

/// 照片视图模型，管理照片数据和用户交互
@Observable
class PhotoViewModel {
    
    // MARK: - Properties
    var photos: [PhotoModel] = []
    var currentPhotoIndex: Int = 0
    var isLoading: Bool = false
    var hasPermission: Bool = false
    var showingDeleteConfirmation: Bool = false
    var errorMessage: String = ""
    var showingError: Bool = false
    
    private let photoService = PhotoService()
    
    // MARK: - Computed Properties
    var currentPhoto: PhotoModel? {
        guard currentPhotoIndex < photos.count else { return nil }
        return photos[currentPhotoIndex]
    }
    
    var nextPhoto: PhotoModel? {
        let nextIndex = currentPhotoIndex + 1
        guard nextIndex < photos.count else { return nil }
        return photos[nextIndex]
    }
    
    var photosMarkedForDeletion: [PhotoModel] {
        return photos.filter { $0.isMarkedForDeletion }
    }
    
    var hasPhotosMarkedForDeletion: Bool {
        return !photosMarkedForDeletion.isEmpty
    }
    
    // MARK: - Initialization
    init() {
        Task {
            await checkPermissionAndLoadPhotos()
        }
    }
    
    // MARK: - Permission & Loading
    @MainActor
    func checkPermissionAndLoadPhotos() async {
        isLoading = true
        
        let permissionGranted = await photoService.requestPhotoLibraryPermission()
        hasPermission = permissionGranted
        
        if permissionGranted {
            await loadPhotos()
        } else {
            errorMessage = "需要访问相册权限才能使用此功能"
            showingError = true
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadPhotos() async {
        isLoading = true
        
        let fetchedPhotos = await photoService.fetchAllPhotos()
        photos = fetchedPhotos
        
        // 预加载前几张图片
        await loadInitialImages()
        
        isLoading = false
    }
    
    @MainActor
    private func loadInitialImages() async {
        let imagesToLoad = min(3, photos.count)
        
        for i in 0..<imagesToLoad {
            await photoService.loadImage(for: photos[i])
        }
    }
    
    // MARK: - Swipe Actions
    func handleSwipe(direction: SwipeDirection) {
        guard let photo = currentPhoto else { return }
        
        switch direction {
        case .left:
            // 不喜欢 - 标记为待删除
            photo.isMarkedForDeletion = true
        case .right:
            // 喜欢 - 什么都不做
            break
        case .none:
            return
        }
        
        moveToNextPhoto()
    }
    
    func moveToNextPhoto() {
        guard currentPhotoIndex < photos.count - 1 else {
            // 已经是最后一张照片
            return
        }
        
        currentPhotoIndex += 1
        
        // 预加载下一张图片
        Task {
            if let nextPhoto = nextPhoto {
                await photoService.loadImage(for: nextPhoto)
            }
        }
    }
    
    func resetCurrentPhotoPosition() {
        currentPhoto?.swipeOffset = 0
        currentPhoto?.rotation = 0
    }
    
    // MARK: - Delete Actions
    func showDeleteConfirmation() {
        showingDeleteConfirmation = true
    }
    
    func deleteMarkedPhotos() {
        let photosToDelete = photosMarkedForDeletion
        guard !photosToDelete.isEmpty else { return }
        
        Task {
            isLoading = true
            let success = await photoService.deletePhotos(photosToDelete)
            
            if success {
                // 从数组中移除已删除的照片
                photos.removeAll { photo in
                    photosToDelete.contains { $0.id == photo.id }
                }
                
                // 调整当前索引
                if currentPhotoIndex >= photos.count {
                    currentPhotoIndex = max(0, photos.count - 1)
                }
            } else {
                errorMessage = "删除照片失败，请重试"
                showingError = true
            }
            
            isLoading = false
        }
    }
    
    func undoMarkForDeletion(_ photo: PhotoModel) {
        photo.isMarkedForDeletion = false
    }
    
    // MARK: - Navigation
    func canGoBack() -> Bool {
        return currentPhotoIndex > 0
    }
    
    func goToPreviousPhoto() {
        guard canGoBack() else { return }
        currentPhotoIndex -= 1
    }
    
    func hasMorePhotos() -> Bool {
        return currentPhotoIndex < photos.count - 1
    }
}
