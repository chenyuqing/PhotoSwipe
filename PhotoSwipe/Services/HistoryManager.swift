//
//  HistoryManager.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import Foundation

class HistoryManager {
    static let shared = HistoryManager()
    
    private let deletedPhotosKey = "deletedPhotos"
    private let keptPhotosKey = "keptPhotos"
    
    private init() {}
    
    // MARK: - 删除记录
    
    func addDeletedPhoto(_ identifier: String) {
        var deletedPhotos = getDeletedPhotos()
        deletedPhotos.insert(identifier)
        UserDefaults.standard.set(Array(deletedPhotos), forKey: deletedPhotosKey)
        
        // 从保留记录中移除（如果存在）
        removeKeptPhoto(identifier)
    }
    
    func removeDeletedPhoto(_ identifier: String) {
        var deletedPhotos = getDeletedPhotos()
        deletedPhotos.remove(identifier)
        UserDefaults.standard.set(Array(deletedPhotos), forKey: deletedPhotosKey)
    }
    
    func isPhotoDeleted(_ identifier: String) -> Bool {
        return getDeletedPhotos().contains(identifier)
    }
    
    private func getDeletedPhotos() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: deletedPhotosKey) ?? []
        return Set(array)
    }
    
    // MARK: - 保留记录
    
    func addKeptPhoto(_ identifier: String) {
        var keptPhotos = getKeptPhotos()
        keptPhotos.insert(identifier)
        UserDefaults.standard.set(Array(keptPhotos), forKey: keptPhotosKey)
        
        // 从删除记录中移除（如果存在）
        removeDeletedPhoto(identifier)
    }
    
    func removeKeptPhoto(_ identifier: String) {
        var keptPhotos = getKeptPhotos()
        keptPhotos.remove(identifier)
        UserDefaults.standard.set(Array(keptPhotos), forKey: keptPhotosKey)
    }
    
    func isPhotoKept(_ identifier: String) -> Bool {
        return getKeptPhotos().contains(identifier)
    }
    
    private func getKeptPhotos() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: keptPhotosKey) ?? []
        return Set(array)
    }
    
    // MARK: - 通用操作
    
    func removeFromHistory(_ identifier: String) {
        removeDeletedPhoto(identifier)
        removeKeptPhoto(identifier)
    }
    
    func clearDeletedPhotos() {
        UserDefaults.standard.removeObject(forKey: deletedPhotosKey)
    }
    
    func clearKeptPhotos() {
        UserDefaults.standard.removeObject(forKey: keptPhotosKey)
    }
    
    func clearAllHistory() {
        clearDeletedPhotos()
        clearKeptPhotos()
    }
    
    func getHistoryStats() -> (deletedCount: Int, keptCount: Int) {
        return (deletedCount: getDeletedPhotos().count, keptCount: getKeptPhotos().count)
    }
}