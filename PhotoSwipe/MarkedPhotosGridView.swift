//
//  MarkedPhotosGridView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

struct MarkedPhotosGridView: View {
    let viewModel: PhotoSwipeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var selectedPhotos: Set<String> = []
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    
    var markedPhotos: [PhotoModel] {
        viewModel.photoService.photos.filter { 
            $0.isMarkedForDeletion && !HistoryManager.shared.isPhotoKept($0.asset.localIdentifier)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if markedPhotos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }
            }
            .navigationTitle("待删除照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !markedPhotos.isEmpty {
                            Button("标记保留") {
                                markSelectedAsKept()
                            }
                            .foregroundColor(.green)
                            .disabled(selectedPhotos.isEmpty)
                            
                            Button("删除选中") {
                                showingDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .disabled(selectedPhotos.isEmpty)
                        }
                    }
                }
            }
        }
        .onAppear {
            // 默认选中所有标记的照片
            selectedPhotos = Set(markedPhotos.map { $0.asset.localIdentifier })
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除 \(selectedPhotos.count) 张照片", role: .destructive) {
                deleteSelectedPhotos()
            }
        } message: {
            Text("确定要删除选中的 \(selectedPhotos.count) 张照片吗？此操作无法撤销。")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有待删除的照片")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("标记为删除的照片会显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var photoGridView: some View {
        VStack {
            // 顶部信息栏
            HStack {
                Text("共 \(markedPhotos.count) 张照片")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(selectedPhotos.count == markedPhotos.count ? "取消全选" : "全选") {
                    if selectedPhotos.count == markedPhotos.count {
                        selectedPhotos.removeAll()
                    } else {
                        selectedPhotos = Set(markedPhotos.map { $0.asset.localIdentifier })
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // 照片网格
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(markedPhotos, id: \.asset.localIdentifier) { photo in
                        PhotoGridItem(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo.asset.localIdentifier)
                        ) {
                            toggleSelection(for: photo)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private func toggleSelection(for photo: PhotoModel) {
        if selectedPhotos.contains(photo.asset.localIdentifier) {
                    selectedPhotos.remove(photo.asset.localIdentifier)
                } else {
                    selectedPhotos.insert(photo.asset.localIdentifier)
                }
    }
    
    private func markSelectedAsKept() {
        // 将选中的照片标记为保留
        for photoId in selectedPhotos {
            HistoryManager.shared.saveKeptPhoto(photoId)
            HistoryManager.shared.removeMarkForDeletion(photoId: photoId)
        }
        
        // 清空选择
        selectedPhotos.removeAll()
        
        // 如果没有待删除的照片了，关闭界面
        if markedPhotos.filter({ !HistoryManager.shared.isPhotoKept($0.asset.localIdentifier) }).isEmpty {
            dismiss()
        }
    }
    
    private func deleteSelectedPhotos() {
        // 只删除选中的照片
        let photosToDelete = markedPhotos.filter { selectedPhotos.contains($0.asset.localIdentifier) }
        
        Task {
            // 先取消未选中照片的标记
            for photo in markedPhotos {
                if !selectedPhotos.contains(photo.asset.localIdentifier) {
                HistoryManager.shared.removeMarkForDeletion(photoId: photo.asset.localIdentifier)
                }
            }
            
            // 删除选中的照片
            await viewModel.deleteSpecificPhotos(photosToDelete)
            
            // 关闭界面
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct PhotoGridItem: View {
    let photo: PhotoModel
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            // 照片缩略图
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
            
            // 选中状态覆盖层
            if isSelected {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(4)
                    }
                    Spacer()
                }
                .frame(width: 120, height: 120)
            }
            
            // 删除标记覆盖层
            if !HistoryManager.shared.isPhotoKept(photo.asset.localIdentifier) {
                Rectangle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(4)
                        }
                        .frame(width: 120, height: 120)
                    )
            }
            
            // 保留标记覆盖层
            if HistoryManager.shared.isPhotoKept(photo.asset.localIdentifier) {
                Rectangle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(4)
                        }
                        .frame(width: 120, height: 120)
                    )
            }
        }
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        
        let targetSize = CGSize(width: 120, height: 120)
        
        manager.requestImage(
            for: photo.asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                self.image = result
            }
        }
    }
}

#Preview {
    MarkedPhotosGridView(viewModel: PhotoSwipeViewModel())
}
