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
    @State private var showingMarkedPhotosGrid = false
    @State private var showingKeptPhotosGrid = false
    
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
                        // 照片索引和处理进度显示
                        if viewModel.photoService.isLoading {
                            Text("加载中...")
                                .foregroundColor(.secondary)
                        } else if !viewModel.photoService.photos.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(viewModel.currentPhotoIndex + 1) / \(viewModel.photoService.photos.count)")
                                    .foregroundColor(.secondary)
                                
                                Text("已处理: \(viewModel.processedPhotosCount) (删除:\(viewModel.markedPhotosCount), 保留:\(viewModel.keptPhotosCount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 管理按钮（整合历史记录功能）
                        if viewModel.markedPhotosCount > 0 || viewModel.keptPhotosCount > 0 || viewModel.hasHistory() {
                            Menu {
                                // 查看待删除照片
                                let markedCount = viewModel.markedPhotosCount
                                if markedCount > 0 {
                                    Button(action: {
                                        showingMarkedPhotosGrid = true
                                    }) {
                                        Label("查看待删除照片 (\(markedCount))", systemImage: "trash.square")
                                    }
                                }
                                
                                // 查看保留照片
                                let keptCount = viewModel.keptPhotosCount
                                if keptCount > 0 {
                                    Button(action: {
                                        showingKeptPhotosGrid = true
                                    }) {
                                        Label("查看保留照片 (\(keptCount))", systemImage: "heart.square")
                                    }
                                }
                                
                                Divider()
                                
                                // 删除所有标记的照片
                                if markedCount > 0 {
                                    Button(action: viewModel.showDeleteConfirmation) {
                                        Label("删除所有标记照片", systemImage: "trash")
                                    }
                                }
                                
                                // 清除所有标记
                                if markedCount > 0 || keptCount > 0 {
                                    Button(action: {
                                        viewModel.clearAllMarks()
                                        HistoryManager.shared.clearKeptPhotos()
                                    }) {
                                        Label("清除所有标记", systemImage: "xmark.circle")
                                    }
                                }
                                
                                // 历史记录统计
                                let stats = viewModel.getExtendedHistoryStats()
                                if stats.deletedCount > 0 || stats.keptCount > 0 {
                                    Button(action: {
                                        viewModel.clearAllRecords()
                                    }) {
                                        Label("清除所有记录", systemImage: "clock.arrow.circlepath")
                                    }
                                }
                            } label: {
                                let totalCount = viewModel.markedPhotosCount + viewModel.keptPhotosCount
                                VStack {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title2)
                                    if totalCount > 0 {
                                        Text("\(totalCount)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                }
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 主要内容区域 - 扩展到全屏
                    ZStack {
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
                        
                        // 底部控制按钮 - 悬浮在图片上方
                        if !viewModel.photoService.photos.isEmpty && !viewModel.photoService.isLoading {
                            VStack {
                                Spacer()
                                
                                HStack(spacing: 60) {
                                    // 删除按钮
                                    Button(action: {
                                        viewModel.swipeRight()
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.title)
                                            .foregroundColor(.red)
                                            .frame(width: 50, height: 50)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(25)
                                            .shadow(radius: 4)
                                    }
                                    
                                    // 撤销按钮
                                    Button(action: {
                                        viewModel.resetCurrentPhotoMark()
                                    }) {
                                        Image(systemName: "arrow.uturn.left")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                            .frame(width: 45, height: 45)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(22.5)
                                            .shadow(radius: 4)
                                    }
                                    
                                    // 保留按钮
                                    Button(action: {
                                        viewModel.swipeLeft()
                                    }) {
                                        Image(systemName: "heart")
                                            .font(.title)
                                            .foregroundColor(.green)
                                            .frame(width: 50, height: 50)
                                            .background(Color.white.opacity(0.9))
                                            .cornerRadius(25)
                                            .shadow(radius: 4)
                                    }
                                }
                                .padding(.bottom, 50)
                            }
                        }
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
            .sheet(isPresented: $showingMarkedPhotosGrid) {
                MarkedPhotosGridView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingKeptPhotosGrid) {
                KeptPhotosGridView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}