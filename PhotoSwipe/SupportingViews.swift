//
//  SupportingViews.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI

// 权限被拒绝视图
struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("无法访问相册")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("请在设置中允许访问照片，以便使用此功能。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }) {
                Text("打开设置")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding()
    }
}

// 加载中视图
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
                .padding()
            
            Text("正在加载照片...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

// 空照片视图
struct EmptyPhotosView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("没有找到照片")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("您的相册中没有照片，请先添加一些照片。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}