//
//  SwipeablePhotoCard.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI
import Photos

struct SwipeablePhotoCard: View {
    let photo: PhotoModel
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                if let image = photo.displayImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    // 显示加载状态
                    ZStack {
                        Color.gray.opacity(0.2)
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("加载中...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            
                // 滑动指示器
                VStack {
                    HStack {
                        // 左滑指示器（喜欢）
                        if offset.width > 50 {
                            Text("❤️ 喜欢")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .opacity(Double(offset.width / 100))
                        }
                        
                        Spacer()
                        
                        // 右滑指示器（不喜欢）
                        if offset.width < -50 {
                            Text("❌ 不喜欢")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .opacity(Double(-offset.width / 100))
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .offset(offset)
            .rotationEffect(.degrees(rotation))
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 10)
                }
                .onEnded { value in
                    let swipeDistance = value.translation.width
                    
                    if swipeDistance > swipeThreshold {
                        // 左滑（喜欢）
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = CGSize(width: 500, height: 0)
                            rotation = 20
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeLeft()
                            resetCard()
                        }
                    } else if swipeDistance < -swipeThreshold {
                        // 右滑（不喜欢）
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = CGSize(width: -500, height: 0)
                            rotation = -20
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeRight()
                            resetCard()
                        }
                    } else {
                        // 回弹
                        withAnimation(.spring()) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
        .onAppear {
            // 优化的图片加载策略
            Task {
                // 总是尝试加载缩略图（如果没有的话）
                if photo.thumbnail == nil {
                    await photo.loadThumbnail()
                }
                
                // 然后异步加载高质量图片
                if photo.image == nil {
                    await photo.loadImage()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 应用从后台恢复时，强制刷新当前图片
            Task {
                if photo.displayImage == nil {
                    await photo.loadThumbnail()
                    await photo.loadImage()
                }
            }
        }
    }
    
    private func resetCard() {
        offset = .zero
        rotation = 0
    }
}

#Preview {
    SwipeablePhotoCard(
        photo: PhotoModel(asset: PHAsset()),
        onSwipeLeft: {},
        onSwipeRight: {}
    )
}