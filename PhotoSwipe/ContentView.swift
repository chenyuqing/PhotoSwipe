//
//  ContentView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var viewModel = PhotoSwipeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 顶部状态栏
                    HStack {
                        VStack(alignment: .leading) {
                            Text("PhotoSwipe")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if viewModel.photoService.isLoading {
                                Text("加载中...")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(viewModel.currentPhotoIndex + 1) / \(viewModel.photoService.photos.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 删除按钮
                        if viewModel.markedPhotosCount > 0 {
                            Button(action: viewModel.showDeleteConfirmation) {
                                VStack {
                                    Image(systemName: "trash")
                                        .font(.title2)
                                    Text("\(viewModel.markedPhotosCount)")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 主要内容区域
                    if viewModel.photoService.authorizationStatus == .denied || viewModel.photoService.authorizationStatus == .restricted {
                        PermissionDeniedView()
                    } else if viewModel.photoService.isLoading {
                        LoadingView()
                    } else if viewModel.photoService.photos.isEmpty {
                        EmptyPhotosView()
                    } else if let currentPhoto = viewModel.currentPhoto {
                        SwipeablePhotoCard(
                            photo: currentPhoto,
                            onSwipeLeft: viewModel.swipeLeft,
                            onSwipeRight: viewModel.swipeRight
                        )
                    }
                    
                    Spacer()
                    
                    // 底部控制按钮
                    if !viewModel.photoService.photos.isEmpty && !viewModel.photoService.isLoading {
                        HStack(spacing: 40) {
                            // 不喜欢按钮
                            Button(action: viewModel.swipeRight) {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            // 撤销按钮
                            Button(action: viewModel.resetCurrentPhotoMark) {
                                Image(systemName: "arrow.uturn.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            // 喜欢按钮
                            Button(action: viewModel.swipeLeft) {
                                Image(systemName: "heart.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.requestPermissionAndLoadPhotos()
                }
            }
            .alert("需要相册权限", isPresented: $viewModel.showingPermissionAlert) {
                Button("去设置") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请在设置中允许访问照片，以便使用此功能。")
            }
            .alert("删除照片", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteMarkedPhotos()
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要删除 \(viewModel.markedPhotosCount) 张标记的照片吗？此操作无法撤销。")
            }
        }
    }
}

#Preview {
    ContentView()
}