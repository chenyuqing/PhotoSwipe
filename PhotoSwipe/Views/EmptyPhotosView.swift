//
//  EmptyPhotosView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI

struct EmptyPhotosView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有找到照片")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("相册中没有照片，或者所有照片都已经处理完成。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    EmptyPhotosView()
}