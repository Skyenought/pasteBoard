import SwiftUI

// ==========================================================
// 共享代码：将 ColorSchemeManager 和 AppColorScheme 的定义放在这里
// ==========================================================

/// 定义用户可以选择的外观模式
enum AppColorScheme: String, CaseIterable, Identifiable {
  case system = "跟随系统"
  case light = "浅色"
  case dark = "深色"
  
  var id: Self { self }
  
  // NEW: 为每个模式提供一个图标
  var iconName: String {
    switch self {
    case .system:
      return "gearshape"
    case .light:
      return "sun.max.fill"
    case .dark:
      return "moon.fill"
    }
  }
  
  /// 将我们的枚举映射到 SwiftUI 的 ColorScheme 类型
  var swiftUIScheme: ColorScheme? {
    switch self {
    case .light:
      return .light
    case .dark:
      return .dark
    case .system:
      return nil // nil 意味着跟随系统
    }
  }
}

/// 一个可观察对象，用于管理和持久化颜色模式设置
@MainActor
class ColorSchemeManager: ObservableObject {
  @Published var colorScheme: AppColorScheme {
    didSet {
      UserDefaults.standard.set(colorScheme.rawValue, forKey: userDefaultsKey)
    }
  }
  
  private let userDefaultsKey = "appAppearanceSetting"
  
  init() {
    let storedValue = UserDefaults.standard.string(forKey: userDefaultsKey)
    self.colorScheme = AppColorScheme(rawValue: storedValue ?? "") ?? .system
  }
}

@main
struct pasteBoardApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  // 移除或注释掉这两个 StateObject，因为 AppDelegate 会提供它们
  // @StateObject private var colorSchemeManager = ColorSchemeManager()
  // @StateObject private var viewModel = ClipboardViewModel()
  
  var body: some Scene {
    // ... 您其余的 Scene 定义保持不变 ...
    WindowGroup {
      ContentView()
        // 现在从 appDelegate 访问这些对象，因为 AppDelegate 是它们的拥有者
        .environmentObject(appDelegate.clipboardViewModel)
        .environmentObject(appDelegate.colorSchemeManager)
    }
    
    WindowGroup(id: "preview-item", for: String.self) { $itemId in
      if let validId = itemId {
        PreviewWindowView(itemId: validId)
            // 现在从 appDelegate 访问这些对象
          .environmentObject(appDelegate.clipboardViewModel)
          .environmentObject(appDelegate.colorSchemeManager)
          .preferredColorScheme(appDelegate.colorSchemeManager.colorScheme.swiftUIScheme)
      }
    }
    .defaultSize(width: 650, height: 550)
    .windowResizability(.contentSize)
  }
}
