//
//  ContentView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = PhotoSwipeViewModel()
    @State private var showingMarkedPhotos = false
    @State private var showingKeptPhotos = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPermissionAlert = false
    @State private var showingSettings = false
    @State private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                (isDarkMode ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                if viewModel.photoService.isLoading {
                    loadingView
                } else if viewModel.photoService.photos.isEmpty {
                    emptyStateView
                } else {
                    photoSwipeView
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMarkedPhotos) {
                MarkedPhotosGridView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingKeptPhotos) {
                KeptPhotosGridView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("需要照片访问权限", isPresented: $showingPermissionAlert) {
                Button("去设置") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请在设置中允许访问照片，以便使用此应用。")
            }
            .alert("确认删除", isPresented: $showingDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteMarkedPhotos()
                    }
                }
            } message: {
                Text("确定要删除 \(viewModel.markedPhotosCount) 张标记的照片吗？此操作无法撤销。")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载照片...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有找到照片")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("请检查照片访问权限")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("检查权限") {
                showingPermissionAlert = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var photoSwipeView: some View {
        GeometryReader { geometry in
            ZStack {
                // 主要的照片卡片
                if let currentPhoto = viewModel.currentPhoto {
                    SwipeablePhotoCard(
                        photo: currentPhoto,
                        onSwipeLeft: {
                            viewModel.swipeLeft()
                        },
                        onSwipeRight: {
                            viewModel.swipeRight()
                        },
                        onTap: {
                            // 可以添加点击事件，比如显示照片详情
                        }
                    )
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // 顶部状态栏
                VStack {
                    HStack {
                        // 设置按钮
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(isDarkMode ? .white : .gray)
                                .frame(width: 44, height: 44)
                                .background((isDarkMode ? Color.black : Color.white).opacity(0.9))
                                .cornerRadius(22)
                                .shadow(radius: 4)
                        }
                        
                        Spacer()
                        
                        // 进度指示器
                        VStack(spacing: 4) {
                            Text("\(viewModel.currentPhotoIndex + 1) / \(viewModel.photoService.photos.count)")
                                .font(.caption)
                                .foregroundColor(isDarkMode ? .white : .black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background((isDarkMode ? Color.black : Color.white).opacity(0.9))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        
                        Spacer()
                        
                        // 标记照片按钮
                        Button(action: {
                            showingMarkedPhotos = true
                        }) {
                            ZStack {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(isDarkMode ? .white : .gray)
                                    .frame(width: 44, height: 44)
                                    .background((isDarkMode ? Color.black : Color.white).opacity(0.9))
                                    .cornerRadius(22)
                                    .shadow(radius: 4)
                                
                                if viewModel.markedPhotosCount > 0 {
                                    Text("\(viewModel.markedPhotosCount)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .frame(width: 18, height: 18)
                                        .background(Color.red)
                                        .cornerRadius(9)
                                        .offset(x: 15, y: -15)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // 底部控制按钮 - 悬浮在图片上方
                    if !viewModel.photoService.photos.isEmpty && !viewModel.photoService.isLoading {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                // 删除按钮 - 位于屏幕宽度的1/4处
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
                                .frame(width: geometry.size.width / 2)
                                .offset(x: -geometry.size.width / 4)
                                
                                // 保留按钮 - 位于屏幕宽度的3/4处
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
                                .frame(width: geometry.size.width / 2)
                                .offset(x: geometry.size.width / 4)
                            }
                        }
                        .frame(height: 50)
                        .padding(.bottom, 50)
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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // 应用从后台恢复时，重新检查当前照片状态
                Task {
                    await viewModel.refreshCurrentPhoto()
                }
            }
        }
    }
}

// 设置视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PhotoSwipeViewModel()
    @State private var showingClearConfirmation = false
    @State private var showingKeptPhotos = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("统计信息") {
                    HStack {
                        Text("待删除照片")
                        Spacer()
                        Text("\(viewModel.markedPhotosCount) 张")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("已保留照片")
                        Spacer()
                        Text("\(HistoryManager.shared.getKeptPhotos().count) 张")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("操作") {
                    Button("查看保留的照片") {
                        showingKeptPhotos = true
                    }
                    
                    Button("清除所有标记", role: .destructive) {
                        showingClearConfirmation = true
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingKeptPhotos) {
            KeptPhotosGridView(viewModel: viewModel)
        }
        .alert("清除标记", isPresented: $showingClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                HistoryManager.shared.clearAllRecords()
                Task {
                    await viewModel.loadPhotos()
                }
            }
        } message: {
            Text("确定要清除所有标记吗？此操作无法撤销。")
        }
    }
}

#Preview {
    ContentView()
}
