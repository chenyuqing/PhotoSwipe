//
//  PhotoModel.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import Foundation
import Photos
import UIKit

@Observable
class PhotoModel: Identifiable {
    let id = UUID()
    let asset: PHAsset
    var image: UIImage?
    var isMarkedForDeletion: Bool = false
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    func loadImage() async {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 400, height: 600),
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                Task { @MainActor in
                    self?.image = image
                    continuation.resume()
                }
            }
        }
    }
}