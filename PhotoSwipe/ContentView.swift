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
    @State private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 主要内容区域 - 铺满全屏
                ZStack {
                    // 背景
                    (isDarkMode ? Color.black : Color.white)
                        .ignoresSafeArea()
                    
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
                        .ignoresSafeArea()
                    }
                    
                    // 顶部状态栏 - 覆盖在图片上
                    VStack {
                        HStack {
                            // 左上角：照片索引和处理进度
                            VStack(alignment: .leading, spacing: 2) {
                                if viewModel.photoService.isLoading {
                                    Text("加载中...")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .fontWeight(.medium)
                                } else if !viewModel.photoService.photos.isEmpty {
                                    Text("\(viewModel.currentPhotoIndex + 1) / \(viewModel.photoService.photos.count)")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .fontWeight(.medium)
                                    
                                    Text("已处理: \(viewModel.processedPhotosCount) (删除:\(viewModel.markedPhotosCount), 保留:\(viewModel.keptPhotosCount))")
                                        .font(.caption)
                                        .foregroundColor(isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7))
                                }
                            }
                            .padding(12)
                            .background((isDarkMode ? Color.black : Color.white).opacity(0.8))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            
                            Spacer()
                            
                            // 右上角：夜间模式切换和管理按钮
                            HStack(spacing: 12) {
                                // 夜间模式切换
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isDarkMode.toggle()
                                    }
                                }) {
                                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                        .font(.title2)
                                        .foregroundColor(isDarkMode ? .yellow : .blue)
                                        .frame(width: 44, height: 44)
                                        .background((isDarkMode ? Color.black : Color.white).opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(radius: 4)
                                }
                                
                                // 管理按钮
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
                                        .frame(width: 44, height: 44)
                                        .background((isDarkMode ? Color.black : Color.white).opacity(0.8))
                                        .cornerRadius(22)
                                        .shadow(radius: 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        // 底部控制按钮 - 悬浮在图片上方
                        if !viewModel.photoService.photos.isEmpty && !viewModel.photoService.isLoading {
                            HStack(spacing: 60) {
                                // 删除按钮
                                Button(action: {
                                    viewModel.swipeRight()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title)
                                        .foregroundColor(.red)
                                        .frame(width: 50, height: 50)
                                        .background((isDarkMode ? Color.black : Color.white).opacity(0.9))
                                        .cornerRadius(25)
                                        .shadow(radius: 4)
                                }
                                
                                // 撤销按钮
                                Button(action: {
                                    viewModel.resetCurrentPhotoMark()
                                }) {
                                    Image(systemName: "arrow.uturn.left")
                                        .font(.title2)
                                        .foregroundColor(isDarkMode ? .white : .gray)
                                        .frame(width: 45, height: 45)
                                        .background((isDarkMode ? Color.black : Color.white).opacity(0.9))
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
                                        .background((isDarkMode ? Color.black : Color.white).opacity(0.9))
                                        .cornerRadius(25)
                                        .shadow(radius: 4)
                                }
                            }
                            .padding(.bottom, 50)
                        }
                    }
                }
            }
            .onAppear {
                // 根据系统设置初始化夜间模式
                isDarkMode = (colorScheme == .dark)
                
                Task {
                    await viewModel.requestPermissionAndLoadPhotos()
                }
            }
            .onChange(of: colorScheme) { _, newValue in
                // 跟随系统主题变化
                isDarkMode = (newValue == .dark)
            }
            .alert("需要相册权限", isPresented: $viewModel.showingPermissionAlert) {
                Button("去设置") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请在设置中允许访问照片，以便使用照片整理功能。")
            }
            .alert("确认删除", isPresented: $viewModel.showingDeleteAlert) {
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteMarkedPhotos()
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要删除 \(viewModel.markedPhotosCount) 张标记的照片吗？此操作不可撤销。")
            }
            .sheet(isPresented: $showingMarkedPhotosGrid) {
                PhotoGridView(
                    photos: viewModel.markedPhotos,
                    title: "待删除照片 (\(viewModel.markedPhotosCount))",
                    onRemove: { photo in
                        viewModel.removeMarkFromPhoto(photo)
                    }
                )
            }
            .sheet(isPresented: $showingKeptPhotosGrid) {
                PhotoGridView(
                    photos: viewModel.keptPhotos,
                    title: "保留照片 (\(viewModel.keptPhotosCount))",
                    onRemove: { photo in
                        viewModel.removeKeepFromPhoto(photo)
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}