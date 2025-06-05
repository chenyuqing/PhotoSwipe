//
//  PermissionDeniedView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("需要相册权限")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("请在设置中允许访问照片，以便使用照片整理功能。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    PermissionDeniedView()
}