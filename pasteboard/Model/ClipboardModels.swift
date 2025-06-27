// file: ClipboardModels.swift
import SwiftUI
import GRDB

// MARK: - UI & ViewModel Layer Models

enum DisplayMode: Int, CaseIterable, Identifiable, Equatable {
  case auto = 0
  case plain = 1
  case code = 2
  case markdown = 3
  
  var id: Self { self }
  
  var name: String {
    switch self {
    case .auto: return "自动"
    case .plain: return "纯文本"
    case .code: return "代码"
    case .markdown: return "Markdown"
    }
  }
  
  var iconName: String {
    switch self {
    case .auto: return "wand.and.stars"
    case .plain: return "text.quote"
    case .code: return "chevron.left.forwardslash.chevron.right"
    case .markdown: return "text.badge.star"
    }
  }
}

struct ClipboardItem: Identifiable, Equatable {
  let id: String
  var date: Date
  var isFavorite: Bool
  var content: ClipboardContent
  
  var customTitle: String?
  var tags: [Tag] = []
  var displayMode: DisplayMode = .plain
  
  var listPreviewText: String {
    if let title = customTitle, !title.isEmpty {
      return "✏️ " + title
    }
    return content.previewText
  }
}

struct Tag: Identifiable, Hashable, Codable {
  var id: Int64
  var name: String
}

enum ClipboardContent: Equatable {
  case text(String, filename: String? = nil)
  case image(NSImage, filename: String? = nil)
  case filePaths([URL])
  
  /// Text for short list previews.
  var previewText: String {
    switch self {
    case .text(let string, let filename):
      if let filename = filename { return "📄 " + filename }
      return string
    case .image(_, let filename):
      if let filename = filename { return "🖼️ " + filename }
      return "🖼️ 图片"
    case .filePaths(let urls):
      if urls.count == 1 { return "📄 " + (urls.first?.lastPathComponent ?? "文件") }
      else { return "🗂️ \(urls.count) 个项目" }
    }
  }
  
  // <<-- NEW: Text for the detailed preview window.
  /// Provides the full text content suitable for a detail view.
  var detailViewText: String? {
    switch self {
    case .text(let string, _):
      // For a text item, return the full text content. THIS IS THE FIX.
      return string
    case .image:
      // An image has no text to preview.
      return nil
    case .filePaths(let urls):
      // For file paths, return a list of paths.
      return urls.map { $0.path }.joined(separator: "\n")
    }
  }
  
  static func == (lhs: ClipboardContent, rhs: ClipboardContent) -> Bool {
    switch (lhs, rhs) {
    case let (.text(lText, lFile), .text(rText, rFile)):
      return lText == rText && lFile == rFile
    case let (.image(lImage, lFile), .image(rImage, rFile)):
      return lImage.tiffRepresentation == rImage.tiffRepresentation && lFile == rFile
    case let (.filePaths(lUrls), .filePaths(rUrls)):
      return lUrls == rUrls
    default:
      return false
    }
  }
}


// MARK: - Database Layer Model (Unchanged)
struct HistoryRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
  var id: String
  var timestamp: Date
  var isFavorite: Bool
  var contentTypeRaw: Int
  
  var textContent: String?
  var binaryContent: Data?
  var filePathsJSON: String?
  var filename: String?
  var customTitle: String?
  var displayModeRaw: Int?
  
  static var databaseTableName = "history"
  
  enum Columns: String, ColumnExpression {
    case id, timestamp, isFavorite, contentTypeRaw, textContent, binaryContent, filePathsJSON, filename, customTitle, displayModeRaw
  }
  
  static let historyTags = hasMany(HistoryTag.self)
  static let tags = hasMany(TagRecord.self, through: historyTags, using: HistoryTag.tag)
  
  enum ContentType: Int {
    case text = 0, image = 1, filePaths = 2
  }
}

struct TagRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
  var id: Int64?
  var name: String
  static var databaseTableName = "tags"
  enum Columns: String, ColumnExpression { case id, name }
  static let historyTags = hasMany(HistoryTag.self)
}

struct HistoryTag: Codable, FetchableRecord, PersistableRecord, TableRecord {
  var historyId: String
  var tagId: Int64
  static var databaseTableName = "history_tags"
  enum Columns: String, ColumnExpression { case historyId, tagId }
  static let history = belongsTo(HistoryRecord.self)
  static let tag = belongsTo(TagRecord.self)
}
