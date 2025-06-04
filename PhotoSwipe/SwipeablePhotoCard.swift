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
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            // 卡片背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)
            
            // 照片内容
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 450)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white, lineWidth: 5)
                    )
            } else {
                // 加载中占位符
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 300, height: 450)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            }
            
            // 喜欢/不喜欢指示器
            VStack {
                if offset.width > 50 {
                    Text("不喜欢")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(10)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                        .rotationEffect(.degrees(-10))
                        .opacity(Double(min(abs(offset.width), 100)) / 100)
                } else if offset.width < -50 {
                    Text("喜欢")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(10)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(10)
                        .rotationEffect(.degrees(10))
                        .opacity(Double(min(abs(offset.width), 100)) / 100)
                }
                
                Spacer()
                
                // 删除标记指示器
                if photo.isMarkedForDeletion {
                    Text("已标记删除")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(8)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(8)
                        .padding(.bottom, 10)
                }
            }
            .padding()
        }
        .frame(width: 320, height: 480)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .opacity(1 - opacity)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                    scale = 0.9 + min(abs(Double(gesture.translation.width) / 1000), 0.1)
                }
                .onEnded { gesture in
                    if abs(gesture.translation.width) > swipeThreshold {
                        // 完成滑动手势
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset.width = gesture.translation.width > 0 ? 500 : -500
                            rotation = gesture.translation.width > 0 ? 15 : -15
                            opacity = 1.0
                        }
                        
                        // 延迟执行回调，等待动画完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if gesture.translation.width > 0 {
                                onSwipeRight()
                            } else {
                                onSwipeLeft()
                            }
                            
                            // 重置状态
                            offset = .zero
                            rotation = 0
                            scale = 0.9
                            opacity = 0
                        }
                    } else {
                        // 未达到滑动阈值，恢复原位
                        withAnimation {
                            offset = .zero
                            rotation = 0
                            scale = 0.9
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring()) {
                scale = 1.0
            }
        }
    }
}