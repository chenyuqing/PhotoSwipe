# PhotoSwipe

一个基于SwiftUI的iOS照片滑动应用，支持Tinder风格的手势交互和照片管理功能。

## 功能特性

- 🎯 **Tinder风格滑动**: 支持左右滑动手势，直观的照片浏览体验
- 📱 **现代SwiftUI界面**: 使用iOS 17+的最新SwiftUI特性构建
- 🖼️ **照片管理**: 浏览设备相册中的所有照片
- 🗑️ **批量删除**: 标记并批量删除不需要的照片
- 🔐 **权限管理**: 智能处理相册访问权限
- ⚡ **性能优化**: 异步加载和图片缓存机制

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI (iOS 17+)
- **架构**: MVVM
- **权限**: Photos Framework
- **异步处理**: async/await
- **状态管理**: @Observable (iOS 17新特性)

## 项目结构

```
PhotoSwipe/
├── PhotoSwipeApp.swift          # 应用入口
├── ContentView.swift            # 主视图
├── Models/
│   └── PhotoModel.swift         # 照片数据模型
├── ViewModels/
│   └── PhotoViewModel.swift     # 视图模型
├── Views/
│   └── SwipeablePhotoView.swift # 可滑动照片视图
├── Services/
│   └── PhotoService.swift       # 照片服务
└── Info.plist                   # 应用配置
```

## 核心功能

### 1. 照片滑动交互
- 向右滑动：标记为"喜欢"
- 向左滑动：标记为"不喜欢"并准备删除
- 滑动阈值：120像素
- 实时视觉反馈：旋转角度和透明度变化

### 2. 权限管理
- 自动检测相册访问权限
- 友好的权限请求界面
- 支持有限权限模式

### 3. 照片管理
- 异步加载照片列表
- 智能图片缓存
- 批量删除确认机制

## 系统要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 安装和运行

1. 克隆项目
```bash
git clone https://github.com/chenyuqing/PhotoSwipe.git
cd PhotoSwipe
```

2. 使用Xcode打开项目
```bash
open PhotoSwipe.xcodeproj
```

3. 选择目标设备或模拟器

4. 运行项目 (⌘+R)

## 使用说明

1. **首次启动**: 应用会请求相册访问权限
2. **浏览照片**: 使用手势左右滑动浏览照片
3. **标记删除**: 向左滑动标记照片为删除
4. **批量删除**: 点击工具栏删除按钮确认删除标记的照片

## 代码特色

### 使用iOS 17新特性
- `@Observable`: 替代传统的`ObservableObject`
- `@Bindable`: 简化数据绑定
- 现代导航API: `NavigationStack`

### 性能优化
- 异步图片加载
- 预加载机制
- 内存管理优化

### 用户体验
- 流畅的动画效果
- 直观的手势交互
- 友好的错误处理

## 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 许可证

MIT License

## 作者

[@chenyuqing](https://github.com/chenyuqing)
