//
//  PhotoGridView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

struct PhotoGridView: View {
    let photos: [PhotoModel]
    let title: String
    let onRemove: (PhotoModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photos) { photo in
                        PhotoGridItem(photo: photo) {
                            onRemove(photo)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PhotoGridItem: View {
    let photo: PhotoModel
    let onRemove: () -> Void
    
    var body: some View {
        ZStack {
            if let image = photo.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
            }
            
            // 移除按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
                Spacer()
            }
        }
        .onAppear {
            // 加载缩略图
            if photo.thumbnail == nil {
                Task {
                    await photo.loadThumbnail()
                }
            }
        }
    }
}

#Preview {
    PhotoGridView(
        photos: [],
        title: "测试照片",
        onRemove: { _ in }
    )
}