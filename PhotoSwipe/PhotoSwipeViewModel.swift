//
//  PhotoSwipeViewModel.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import Foundation
import Photos
import SwiftUI

@Observable
class PhotoSwipeViewModel {
    let photoService = PhotoService()
    var currentPhotoIndex: Int = 0
    var showingPermissionAlert: Bool = false
    var showingDeleteConfirmation: Bool = false
    
    var currentPhoto: PhotoModel? {
        guard !photoService.photos.isEmpty, currentPhotoIndex < photoService.photos.count else {
            return nil
        }
        return photoService.photos[currentPhotoIndex]
    }
    
    var markedPhotosCount: Int {
        return photoService.getMarkedPhotosCount()
    }
    
    @MainActor
    func requestPermissionAndLoadPhotos() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .notDetermined:
            await photoService.requestPhotoLibraryAccess()
        case .restricted, .denied:
            showingPermissionAlert = true
        case .authorized, .limited:
            await photoService.requestPhotoLibraryAccess()
        @unknown default:
            await photoService.requestPhotoLibraryAccess()
        }
    }
    
    func swipeLeft() {
        // 喜欢照片，不标记删除，移到下一张
        moveToNextPhoto()
    }
    
    func swipeRight() {
        // 不喜欢照片，标记删除，移到下一张
        if let currentPhoto = currentPhoto {
            currentPhoto.isMarkedForDeletion = true
        }
        moveToNextPhoto()
    }
    
    func resetCurrentPhotoMark() {
        // 撤销当前照片的标记
        if let currentPhoto = currentPhoto {
            currentPhoto.isMarkedForDeletion = false
        }
    }
    
    private func moveToNextPhoto() {
        // 预加载下一张图片
        let nextIndex = currentPhotoIndex + 1
        if nextIndex < photoService.photos.count {
            Task {
                await photoService.photos[nextIndex].loadImage()
            }
        }
        
        // 移动到下一张照片
        if currentPhotoIndex < photoService.photos.count - 1 {
            currentPhotoIndex += 1
        }
    }
    
    func showDeleteConfirmation() {
        showingDeleteConfirmation = true
    }
    
    @MainActor
    func deleteMarkedPhotos() async {
        await photoService.deleteMarkedPhotos()
        
        // 如果当前索引超出范围，重置为最后一张
        if currentPhotoIndex >= photoService.photos.count && !photoService.photos.isEmpty {
            currentPhotoIndex = photoService.photos.count - 1
        }
    }
}