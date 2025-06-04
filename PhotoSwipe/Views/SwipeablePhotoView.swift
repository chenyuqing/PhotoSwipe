//
//  SwipeablePhotoView.swift
//  PhotoSwipe
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI
import Photos

/// 可滑动的照片视图组件
struct SwipeablePhotoView: View {
    let photo: PhotoModel
    let onSwipe: (SwipeDirection) -> Void
    let onReset: () -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 400)
                    .clipped()
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width / 10)))
                    .scaleEffect(isDragging ? 0.95 : 1.0)
                    .overlay(
                        // 滑动指示器
                        Group {
                            if abs(dragOffset.width) > 50 {
                                VStack {
                                    Image(systemName: dragOffset.width > 0 ? "heart.fill" : "xmark")
                                        .font(.system(size: 50))
                                        .foregroundColor(dragOffset.width > 0 ? .green : .red)
                                        .opacity(min(abs(dragOffset.width) / swipeThreshold, 1.0))
                                    
                                    Text(dragOffset.width > 0 ? "喜欢" : "删除")
                                        .font(.headline)
                                        .foregroundColor(dragOffset.width > 0 ? .green : .red)
                                        .opacity(min(abs(dragOffset.width) / swipeThreshold, 1.0))
                                }
                            }
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                isDragging = true
                                dragOffset = gesture.translation
                                
                                // 实时更新照片模型的状态
                                photo.swipeOffset = dragOffset.width
                                
                                // 计算旋转角度
                                let rotationAngle = Double(dragOffset.width / 10)
                                photo.rotation = rotationAngle
                            }
                            .onEnded { gesture in
                                isDragging = false
                                
                                // 确定滑动方向
                                let swipeDirection: SwipeDirection
                                if dragOffset.width > swipeThreshold {
                                    swipeDirection = .right
                                } else if dragOffset.width < -swipeThreshold {
                                    swipeDirection = .left
                                } else {
                                    swipeDirection = .none
                                }
                                
                                // 实时更新照片模型的状态
                                photo.swipeOffset = dragOffset.width
                                
                                // 计算旋转角度
                                let rotationAngle = Double(dragOffset.width / 10)
                                photo.rotation = rotationAngle
                            }
                            .onEnded { gesture in
                                isDragging = false
                                
                                // 如果超过阈值，触发滑动动作
                                if abs(dragOffset.width) > swipeThreshold {
                                    // 添加动画效果，让卡片飞出屏幕
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        dragOffset.width = dragOffset.width > 0 ? 1000 : -1000
                                    }
                                    
                                    // 延迟调用滑动回调，等待动画完成
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onSwipe(swipeDirection)
                                        dragOffset = .zero
                                    }
                                } else {
                                    // 未达到阈值，恢复原位
                                    withAnimation(.spring()) {
                                        dragOffset = .zero
                                        photo.swipeOffset = 0
                                        photo.rotation = 0
                                        onReset()
                                    }
                                }
                            }
                    )
                    .animation(isDragging ? nil : .spring(), value: dragOffset)
            } else {
                // 加载中占位符
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 300, height: 400)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                    )
            }
        }
        .frame(width: 300, height: 400)
    }
}

#Preview {
    let asset = PHAsset()
    let photo = PhotoModel(asset: asset)
    photo.image = UIImage(systemName: "photo")
    
    return SwipeablePhotoView(
        photo: photo,
        onSwipe: { _ in },
        onReset: {}
    )
}
