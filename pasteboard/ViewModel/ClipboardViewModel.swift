// file: ClipboardViewModel.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum FilterMode: String, CaseIterable, Identifiable {
    case all = "全部"
    case favorites = "收藏"
    var id: Self { self }
}

@MainActor
class ClipboardViewModel: ObservableObject {
    @Published var clipboardHistory: [ClipboardItem] = []
    
    // Filter properties
    @Published var filterMode: FilterMode = .all {
        didSet { Task { await loadHistory(isLoadMore: false) } }
    }
    @Published var selectedTag: Tag? = nil {
        didSet { Task { await loadHistory(isLoadMore: false) } }
    }
    @Published var searchText: String = "" {
        didSet {
            if !searchText.isEmpty {
                selectedTag = nil // Clear tag filter when searching
            }
            Task { await loadHistory(isLoadMore: false) }
        }
    }
    // <<-- NEW: Date filter properties
    @Published var startDateFilter: Date? = nil
    @Published var endDateFilter: Date? = nil
    
    // Editing and Management state
    @Published var selectedItemForEditing: ClipboardItem? = nil
    @Published var isShowingTagManagement = false
    
    @Published var allTags: [Tag] = []
    
    @Published var tagDeletionError: String? = nil
    @Published var isShowingTagDeletionErrorAlert = false
    
    // Pagination and loading state
    @Published private(set) var isLoading = false
    @Published private(set) var canLoadMoreData = true
    private var currentPage = 0
    private let pageSize = 30
    
    // Internal properties
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var skipNextClipboard: Bool = false
    private let dateFormatter: DateFormatter
    
    // <<-- NEW: Computed property to easily check if a date filter is applied
    var isDateFilterActive: Bool {
        startDateFilter != nil && endDateFilter != nil
    }
    
    init() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.dateFormatter = df
    }
    
    func activate() {
        Task {
            await loadAllTags()
            await loadHistory(isLoadMore: false)
            startClipboardMonitor()
        }
    }
    
    // MARK: - Date Filtering
    
    func setDateFilter(start: Date, end: Date) {
        // 确保开始日期是当天的开始（00:00:00）
        let startOfDay = Calendar.current.startOfDay(for: start)
        
        // 计算结束日期之后那天的开始（例如，如果选择6月7日，则计算出6月8日的 00:00:00）
        let startOfEndDay = Calendar.current.startOfDay(for: end)
        guard let endOfRange = Calendar.current.date(byAdding: .day, value: 1, to: startOfEndDay) else {
            // 如果计算失败，则退回到一个安全的默认值
            self.endDateFilter = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end)
            return
        }
        
        self.startDateFilter = startOfDay
        self.endDateFilter = endOfRange // endDate 现在是 "第二天零点"
        
        Task { await loadHistory(isLoadMore: false) }
    }
    
    func clearDateFilter() {
        self.startDateFilter = nil
        self.endDateFilter = nil
        Task { await loadHistory(isLoadMore: false) }
    }
    
    
    // MARK: - View Actions
    
    func loadMoreContent() {
        guard !isLoading && canLoadMoreData else { return }
        Task { await loadHistory(isLoadMore: true) }
    }
    
    func selectItemForEditing(_ item: ClipboardItem?) {
        Task { selectedItemForEditing = item }
    }
    
    func exitEditingMode() {
        Task {
            let itemToUpdate = selectedItemForEditing
            selectedItemForEditing = nil
            if itemToUpdate != nil { await loadAllTags() }
            await loadHistory(isLoadMore: false)
        }
    }
    
    func copyToClipboard(item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        var success = false
        switch item.content {
        case .text(let string, _): success = pb.setString(string, forType: .string)
        case .image(let image, _): success = pb.writeObjects([image])
        case .filePaths(let urls): success = pb.writeObjects(urls as [NSPasteboardWriting])
        }
        if success { skipNextClipboard = true }
    }
    
    // 修改 formattedDate 方法
    func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"  // 使用 yyyy-MM-dd 格式
        return formatter.string(from: date)
    }
    
    func deleteItem(with id: String) {
        Task {
            try? await DatabaseManager.shared.delete(id: id)
            clipboardHistory.removeAll { $0.id == id }
        }
    }
    
    func deleteAllNonFavorites() {
        Task {
            try? await DatabaseManager.shared.deleteAllNonFavorites()
            await loadHistory(isLoadMore: false)
        }
    }
    
    func toggleFavorite(for item: ClipboardItem) {
        Task {
            if let index = clipboardHistory.firstIndex(where: { $0.id == item.id }) {
                clipboardHistory[index].isFavorite.toggle()
            }
            if selectedItemForEditing?.id == item.id {
                selectedItemForEditing?.isFavorite.toggle()
            }
            try? await DatabaseManager.shared.toggleFavorite(id: item.id)
        }
    }
    
    func updateDisplayMode(for item: ClipboardItem, to newMode: DisplayMode) {
        if let index = clipboardHistory.firstIndex(where: { $0.id == item.id }) {
            clipboardHistory[index].displayMode = newMode
        }
        if selectedItemForEditing?.id == item.id {
            selectedItemForEditing?.displayMode = newMode
        }
        Task { try? await DatabaseManager.shared.updateDisplayMode(for: item.id, mode: newMode) }
    }
    
    func updateCustomTitle(for item: ClipboardItem, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard item.customTitle != trimmedTitle else { return }
        Task { try? await DatabaseManager.shared.updateCustomTitle(for: item.id, title: trimmedTitle) }
    }
    
    func updateTags(for item: ClipboardItem, tags: [Tag]) {
        let newTagNames = Set(tags.map { $0.name })
        let oldTagNames = Set(item.tags.map { $0.name })
        guard newTagNames != oldTagNames else { return }
        Task {
            let tagNames = tags.map { $0.name }
            try? await DatabaseManager.shared.updateTags(for: item.id, with: tagNames)
        }
    }
    
    // MARK: - Tag Management & Filtering
    
    func toggleTagSelection(_ tag: Tag?) {
        // If the passed tag is the same as the selected one, deselect (set to nil).
        // Otherwise, select the new tag.
        // If nil is passed, it always resets.
        if selectedTag == tag {
            selectedTag = nil
        } else {
            selectedTag = tag
        }
    }
    
    func addTag(name: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        do {
            try await DatabaseManager.shared.addTag(name: trimmedName)
            await loadAllTags()
        } catch { print("Failed to add tag: \(error)") }
    }
    
    func renameTag(_ tag: Tag, to newName: String) async {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        do {
            try await DatabaseManager.shared.renameTag(id: tag.id, newName: newName)
            await loadAllTags()
        } catch { print("Failed to rename tag: \(error)") }
    }
    
    func deleteTag(_ tag: Tag) async {
        if selectedTag?.id == tag.id {
            selectedTag = nil
        }
        do {
            try await DatabaseManager.shared.deleteTag(id: tag.id)
            await loadAllTags()
        } catch {
            // 将错误信息赋值给 @Published 属性
            // a. 获取本地化的错误描述
            let localizedError = error as? LocalizedError
            self.tagDeletionError = localizedError?.errorDescription ?? "一个未知错误发生。"
            // b. 触发 Alert 显示
            self.isShowingTagDeletionErrorAlert = true
        }
    }
    
    // MARK: - Data Loading
    func loadAllTags() async {
        do { self.allTags = try await DatabaseManager.shared.fetchAllTags() }
        catch { print("加载所有标签失败: \(error)") }
    }
    
    private func loadHistory(isLoadMore: Bool = false) async {
        guard !isLoading else { return }
        
        if !isLoadMore {
            currentPage = 0
            canLoadMoreData = true
            clipboardHistory = []
        }
        
        isLoading = true
        
        do {
            let offset = currentPage * pageSize
            
            // <<-- CRITICAL FIX: 将日期过滤器参数传递给数据库查询 -->>
            let newItems = try await DatabaseManager.shared.fetch(
                filter: self.filterMode,
                tag: self.selectedTag,
                searchQuery: self.searchText,
                startDate: self.startDateFilter, // <-- 之前缺失了这个参数
                endDate: self.endDateFilter,   // <-- 之前缺失了这个参数
                limit: pageSize,
                offset: offset
            )
            
            if newItems.isEmpty {
                canLoadMoreData = false
            } else {
                clipboardHistory.append(contentsOf: newItems)
                currentPage += 1
                if newItems.count < pageSize { canLoadMoreData = false }
            }
        }
        catch { print("从数据库加载历史失败: \(error)"); canLoadMoreData = false }
        
        isLoading = false
    }
    
    private func startClipboardMonitor() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { await self?.checkClipboard() }
        }
    }
    
    private func checkClipboard() async {
        guard NSPasteboard.general.changeCount != lastChangeCount else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        if skipNextClipboard { skipNextClipboard = false; return }
        if let newItem = createItemFromPasteboard() {
            try? await DatabaseManager.shared.save(item: newItem)
            
            if filterMode == .all && selectedTag == nil && searchText.isEmpty {
                clipboardHistory.insert(newItem, at: 0)
            }
        }
    }
    
    private func createItemFromPasteboard() -> ClipboardItem? {
        let pb = NSPasteboard.general
        if let fileURLs = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !fileURLs.isEmpty {
            if fileURLs.count == 1, let url = fileURLs.first,
               let type = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
               let uttype = UTType(type) {
                if uttype.conforms(to: .image), let image = NSImage(contentsOf: url) {
                    return ClipboardItem(id: UUID().uuidString, date: Date(), isFavorite: false, content: .image(image, filename: url.lastPathComponent))
                }
                if uttype.conforms(to: .text), let text = try? String(contentsOf: url, encoding: .utf8) {
                    if case .text(let lastText, _) = self.clipboardHistory.first?.content, lastText == text { return nil }
                    return ClipboardItem(id: UUID().uuidString, date: Date(), isFavorite: false, content: .text(text, filename: url.lastPathComponent))
                }
            }
            return ClipboardItem(id: UUID().uuidString, date: Date(), isFavorite: false, content: .filePaths(fileURLs))
        } else if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let firstImage = images.first {
            return ClipboardItem(id: UUID().uuidString, date: Date(), isFavorite: false, content: .image(firstImage))
        } else if let copied = pb.string(forType: .string), !copied.isEmpty {
            if case .text(let lastText, _) = self.clipboardHistory.first?.content, lastText == copied { return nil }
            return ClipboardItem(id: UUID().uuidString, date: Date(), isFavorite: false, content: .text(copied))
        }
        return nil
    }
}

