// file: DatabaseManager.swift
import Foundation
import GRDB
import AppKit

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let dbQueue: DatabaseQueue
    
    enum TagDeletionError: LocalizedError {
        case isCurrentlyInUse(count: Int)
        
        var errorDescription: String? {
            switch self {
            case .isCurrentlyInUse(let count):
                return "此标签正被 \(count) 条记录使用，请先从这些记录中移除该标签，然后再尝试删除。"
            }
        }
    }
    
    private init() {
        do {
            let fileManager = FileManager.default
            // 1. 获取“文稿”文件夹的 URL
            let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            print(documentsDirectory)
            // 2. 在“文稿”文件夹下创建一个名为 "pasteBoard" 的子文件夹
            let dbDirectory = documentsDirectory.appendingPathComponent("pasteBoard")
            try fileManager.createDirectory(at: dbDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // 3. 拼接最终的数据库文件 URL
            let dbURL = dbDirectory.appendingPathComponent("history.sqlite")
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            try setupDatabase()
        } catch {
            fatalError("数据库初始化失败: \(error)")
        }
    }
    
    private func setupDatabase() throws {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "history") { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .datetime).notNull().indexed()
                t.column("isFavorite", .boolean).notNull()
                t.column("contentTypeRaw", .integer).notNull()
                t.column("textContent", .text)
                t.column("binaryContent", .blob)
                t.column("filePathsJSON", .text)
            }
        }
        
        migrator.registerMigration("v2_addFilename") { db in try db.alter(table: "history") { t in t.add(column: "filename", .text) } }
        migrator.registerMigration("v4_addCustomTitle") { db in try db.alter(table: "history") { t in t.add(column: "customTitle", .text) } }
        
        migrator.registerMigration("v5_addTags") { db in
            try db.create(table: "tags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique(onConflict: .ignore)
            }
            
            try db.create(table: "history_tags") { t in
                t.column("historyId", .text).notNull().references("history", onDelete: .cascade)
                t.column("tagId", .integer).notNull().references("tags", onDelete: .cascade)
                t.primaryKey(["historyId", "tagId"])
            }
        }
        
        migrator.registerMigration("v7_addDisplayMode") { db in
            try db.alter(table: "history") { t in
                t.add(column: "displayModeRaw", .integer).notNull().defaults(to: 0)
            }
        }
        
        try migrator.migrate(dbQueue)
    }
    
    // MARK: - CRUD Operations
    
    func save(item: ClipboardItem) async throws {
        let record = historyRecord(from: item)
        try await dbQueue.write { db in
            try record.save(db)
        }
    }
    
    // <<-- THIS METHOD IS NOW CORRECTED
    func fetch(filter: FilterMode, tag: Tag? = nil, searchQuery: String = "", startDate: Date? = nil, endDate: Date? = nil, limit: Int, offset: Int) async throws -> [ClipboardItem] {
        let records: [HistoryRecord] = try await dbQueue.read { db in
            var request: QueryInterfaceRequest<HistoryRecord>
            
            switch filter {
            case .all:
                request = HistoryRecord.all()
            case .favorites:
                request = HistoryRecord.filter(HistoryRecord.Columns.isFavorite == true)
            }
            
            // <<-- CHANGE: 修正日期过滤逻辑以使用半开区间 -->>
            // 如果提供了日期范围，就添加日期过滤条件
            if let start = startDate, let end = endDate {
                // 使用半开区间查询 (>= start, < end)，这是最精确和健壮的方式
                request = request.filter(HistoryRecord.Columns.timestamp >= start &&
                                         HistoryRecord.Columns.timestamp < end)
            }
            
            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedQuery.isEmpty {
                let pattern = "%\(trimmedQuery)%"
                let tagsAlias = TableAlias(name: "aliased_tags")
                request = request
                    .joining(optional: HistoryRecord.tags.aliased(tagsAlias))
                    .filter(
                        HistoryRecord.Columns.customTitle.like(pattern) ||
                        HistoryRecord.Columns.textContent.like(pattern) ||
                        tagsAlias[Column("name")].like(pattern)
                    )
                    .distinct()
            }
            
            if let tag = tag {
                request = request.joining(required: HistoryRecord.historyTags.filter(HistoryTag.Columns.tagId == tag.id))
            }
            
            request = request.order(HistoryRecord.Columns.timestamp.desc)
            return try request.limit(limit, offset: offset).fetchAll(db)
        }
        
        var items: [ClipboardItem] = []
        for record in records {
            if var item = clipboardItem(from: record) {
                item.tags = try await fetchTags(for: item.id)
                items.append(item)
            }
        }
        return items
    }
    
    func delete(id: String) async throws { _ = try await dbQueue.write { db in try HistoryRecord.deleteOne(db, key: id) } }
    
    func deleteAllNonFavorites() async throws { _ = try await dbQueue.write { db in try HistoryRecord.filter(Column("isFavorite") == false).deleteAll(db) } }
    
    func toggleFavorite(id: String) async throws {
        try await dbQueue.write { db in
            if var record = try HistoryRecord.fetchOne(db, key: id) { record.isFavorite.toggle(); try record.update(db) }
        }
    }
    
    func updateDisplayMode(for id: String, mode: DisplayMode) async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "UPDATE history SET displayModeRaw = ? WHERE id = ?", arguments: [mode.rawValue, id])
        }
    }
    
    func updateCustomTitle(for id: String, title: String) async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "UPDATE history SET customTitle = ? WHERE id = ?", arguments: [title, id])
        }
    }
    
    // MARK: - Tag Operations
    
    func addTag(name: String) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        try await dbQueue.write { db in
            let newRecord = TagRecord(name: trimmedName)
            try newRecord.insert(db, onConflict: .ignore)
        }
    }
    
    func fetchAllTags() async throws -> [Tag] {
        try await dbQueue.read { db in
            let tagRecords = try TagRecord.order(Column("name")).fetchAll(db)
            return tagRecords.compactMap { $0.id != nil ? Tag(id: $0.id!, name: $0.name) : nil }
        }
    }
    
    func fetchTags(for historyId: String) async throws -> [Tag] {
        try await dbQueue.read { db in
            guard let historyRecord = try HistoryRecord.fetchOne(db, key: historyId) else {
                return []
            }
            let tagRecords = try historyRecord.request(for: HistoryRecord.tags).fetchAll(db)
            return tagRecords.compactMap {
                guard let id = $0.id else { return nil }
                return Tag(id: id, name: $0.name)
            }
        }
    }
    
    func updateTags(for historyId: String, with tagNames: [String]) async throws {
        try await dbQueue.write { db in
            try HistoryTag.filter(HistoryTag.Columns.historyId == historyId).deleteAll(db)
            for tagName in tagNames {
                let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { continue }
                
                var tagRecord: TagRecord? = try TagRecord.filter(Column("name") == trimmedName).fetchOne(db)
                
                if tagRecord == nil {
                    let newTag = TagRecord(name: trimmedName)
                    try newTag.insert(db, onConflict: .ignore)
                    tagRecord = try TagRecord.filter(Column("name") == trimmedName).fetchOne(db)
                }
                
                if let tagId = tagRecord?.id {
                    let historyTag = HistoryTag(historyId: historyId, tagId: tagId)
                    try historyTag.insert(db, onConflict: .ignore)
                }
            }
        }
    }
    
    func renameTag(id: Int64, newName: String) async throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        try await dbQueue.write { db in
            try db.execute(sql: "UPDATE tags SET name = ? WHERE id = ?", arguments: [trimmedName, id])
        }
    }
    
    func deleteTag(id: Int64) async throws {
        try await dbQueue.write { db in
            let usageCount = try HistoryTag
                .filter(HistoryTag.Columns.tagId == id)
                .fetchCount(db)
            
            if usageCount > 0 {
                throw TagDeletionError.isCurrentlyInUse(count: usageCount)
            } else {
                _ = try TagRecord.deleteOne(db, key: id)
            }
        }
    }
    
    // MARK: - Conversion Helpers
    
    private func clipboardItem(from record: HistoryRecord) -> ClipboardItem? {
        let content: ClipboardContent
        guard let contentType = HistoryRecord.ContentType(rawValue: record.contentTypeRaw) else { return nil }
        
        switch contentType {
        case .text:
            guard let text = record.textContent else { return nil }
            content = .text(text, filename: record.filename)
        case .image:
            guard let data = record.binaryContent, let image = NSImage(data: data) else { return nil }
            content = .image(image, filename: record.filename)
        case .filePaths:
            guard let jsonString = record.filePathsJSON,
                  let jsonData = jsonString.data(using: .utf8),
                  let bookmarksAsBase64 = try? JSONDecoder().decode([String].self, from: jsonData) else { return nil }
            let urls = bookmarksAsBase64.compactMap { base64String -> URL? in
                guard let bookmarkData = Data(base64Encoded: base64String) else { return nil }
                var isStale = false
                return try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            }
            content = .filePaths(urls)
        }
        
        let displayMode = DisplayMode(rawValue: record.displayModeRaw ?? 0) ?? .auto
        
        return ClipboardItem(id: record.id, date: record.timestamp, isFavorite: record.isFavorite, content: content, customTitle: record.customTitle, tags: [], displayMode: displayMode)
    }
    
    private func historyRecord(from item: ClipboardItem) -> HistoryRecord {
        var record = HistoryRecord(id: item.id, timestamp: item.date, isFavorite: item.isFavorite, contentTypeRaw: 0, customTitle: item.customTitle, displayModeRaw: item.displayMode.rawValue)
        
        switch item.content {
        case .text(let string, let filename):
            record.contentTypeRaw = HistoryRecord.ContentType.text.rawValue
            record.textContent = string
            record.filename = filename
        case .image(let image, let filename):
            record.contentTypeRaw = HistoryRecord.ContentType.image.rawValue
            record.binaryContent = image.tiffRepresentation
            record.filename = filename
        case .filePaths(let urls):
            record.contentTypeRaw = HistoryRecord.ContentType.filePaths.rawValue
            let bookmarksAsBase64 = urls.compactMap { try? $0.bookmarkData(options: .withSecurityScope).base64EncodedString() }
            if let jsonData = try? JSONEncoder().encode(bookmarksAsBase64), let jsonString = String(data: jsonData, encoding: .utf8) {
                record.filePathsJSON = jsonString
            }
        }
        return record
    }
}



