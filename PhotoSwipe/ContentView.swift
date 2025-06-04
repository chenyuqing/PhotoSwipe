//
//  ContentView.swift
//  PhotoSwipe
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI
import Photos

/// 主视图，包含照片滑动功能和权限管理
struct ContentView: View {
    @State private var viewModel = PhotoViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasPermission {
                    permissionDeniedView
                } else if viewModel.photos.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("照片滑动")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    deleteButton
                }
            }
            .alert("删除确认", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    viewModel.deleteMarkedPhotos()
                }
            } message: {
                Text("确定要删除 \(viewModel.photosMarkedForDeletion.count) 张照片吗？此操作无法撤销。")
            }
            .alert("错误", isPresented: $viewModel.showingError) {
                Button("确定") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("正在加载照片...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 权限被拒绝视图
    private var permissionDeniedView: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 15) {
                Text("需要相册访问权限")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("为了使用照片滑动功能，请在设置中允许访问您的照片库。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 15) {
                Button("打开设置") {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("重新检查权限") {
                    Task {
                        await viewModel.checkPermissionAndLoadPhotos()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    // MARK: - 权限请求视图
    private var permissionRequestView: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 15) {
                Text("访问您的照片")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("我们需要访问您的照片库来显示和管理照片。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("允许访问") {
                Task {
                    await viewModel.checkPermissionAndLoadPhotos()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                Text("没有找到照片")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("您的相册中没有照片，请先添加一些照片。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("重新加载") {
                Task {
                    await viewModel.loadPhotos()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - 主内容视图
    private var mainContentView: some View {
        VStack(spacing: 20) {
            // 进度指示器
            progressIndicator
            
            // 照片堆叠视图
            photoStackView
            
            // 操作按钮
            actionButtons
            
            // 待删除照片提示
            if viewModel.hasPhotosMarkedForDeletion {
                deletionSummary
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 进度指示器
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(viewModel.currentPhotoIndex + 1) / \(viewModel.photos.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if viewModel.hasPhotosMarkedForDeletion {
                    Text("待删除: \(viewModel.photosMarkedForDeletion.count)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            ProgressView(value: Double(viewModel.currentPhotoIndex + 1), total: Double(viewModel.photos.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
    }
    
    // MARK: - 照片堆叠视图
    private var photoStackView: some View {
        ZStack {
            // 下一张照片（背景）
            if let nextPhoto = viewModel.nextPhoto {
                SwipeablePhotoView(
                    photo: nextPhoto,
                    onSwipe: { _ in },
                    onReset: {}
                )
                .scaleEffect(0.95)
                .opacity(0.5)
                .allowsHitTesting(false)
            }
            
            // 当前照片
            if let currentPhoto = viewModel.currentPhoto {
                SwipeablePhotoView(
                    photo: currentPhoto,
                    onSwipe: { direction in
                        viewModel.handleSwipe(direction: direction)
                    },
                    onReset: {
                        viewModel.resetCurrentPhotoPosition()
                    }
                )
            }
        }
        .frame(height: 450)
    }
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 40) {
            // 不喜欢按钮
            Button {
                viewModel.handleSwipe(direction: .left)
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            
            // 返回按钮
            Button {
                viewModel.goToPreviousPhoto()
            } label: {
                Image(systemName: "arrow.uturn.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.gray)
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            .disabled(!viewModel.canGoBack())
            .opacity(viewModel.canGoBack() ? 1.0 : 0.5)
            
            // 喜欢按钮
            Button {
                viewModel.handleSwipe(direction: .right)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
        }
    }
    
    // MARK: - 删除按钮
    private var deleteButton: some View {
        Button {
            viewModel.showDeleteConfirmation()
        } label: {
            Image(systemName: "trash")
                .foregroundColor(viewModel.hasPhotosMarkedForDeletion ? .red : .gray)
        }
        .disabled(!viewModel.hasPhotosMarkedForDeletion)
    }
    
    // MARK: - 待删除照片摘要
    private var deletionSummary: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("\(viewModel.photosMarkedForDeletion.count) 张照片已标记为删除")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Button("撤销全部") {
                    for photo in viewModel.photosMarkedForDeletion {
                        viewModel.undoMarkForDeletion(photo)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("立即删除") {
                    viewModel.showDeleteConfirmation()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - 辅助方法
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    ContentView()
}
