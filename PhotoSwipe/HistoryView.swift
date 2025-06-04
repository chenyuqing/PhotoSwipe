//
//  HistoryView.swift
//  PhotoSwipe
//
//  Created by Tim on 4/6/25.
//

import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: PhotoSwipeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    @State private var showingClearMarksConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 标题
                Text("历史记录")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 统计信息卡片
                statisticsCard
                
                // 操作按钮
                actionButtons
                
                Spacer()
                
                // 说明文字
                explanationText
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .alert("清除所有历史记录", isPresented: $showingClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                viewModel.clearAllHistory()
            }
        } message: {
            Text("这将清除所有标记和删除历史记录，此操作无法撤销。")
        }
        .alert("清除所有标记", isPresented: $showingClearMarksConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                viewModel.clearAllMarks()
            }
        } message: {
            Text("这将清除所有待删除标记，但保留删除历史记录。")
        }
    }
    
    private var statisticsCard: some View {
        let stats = viewModel.getHistoryStats()
        
        return VStack(spacing: 16) {
            HStack {
                VStack {
                    Text("\(stats.markedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("待删除")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(stats.deletedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("已删除")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingClearMarksConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("清除所有标记")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.getHistoryStats().markedCount == 0)
            
            Button {
                showingClearConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("清除所有历史记录")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.hasHistoryData)
        }
    }
    
    private var explanationText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("说明：")
                .font(.headline)
            
            Text("• 待删除：标记为删除但尚未执行删除的照片数量")
            Text("• 已删除：已经从相册中删除的照片数量")
            Text("• 应用会自动保存您的选择，重新打开应用时会恢复之前的标记状态")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    HistoryView(viewModel: PhotoSwipeViewModel())
}