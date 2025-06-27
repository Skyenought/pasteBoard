// file: TagEditorView.swift
import SwiftUI

struct TagEditorView: View {
  @Binding var tags: [Tag]
  let allTags: [Tag]
  @State private var newTagText = ""
  
  private var suggestedTags: [Tag] {
    if newTagText.isEmpty { return [] }
    let currentTagNames = Set(tags.map { $0.name.lowercased() })
    return allTags.filter {
      $0.name.lowercased().contains(newTagText.lowercased()) && !currentTagNames.contains($0.name.lowercased())
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Display current tags
      if !tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ForEach(tags) { tag in
              TagPill(tag: tag, onRemove: { removeTag(tag) })
            }
          }
        }
      }
      
      // Input field for new tags
      TextField("添加或查找标签...", text: $newTagText, onCommit: addTagFromInput)
        .textFieldStyle(RoundedBorderTextFieldStyle())
      
      // Suggestions
      if !suggestedTags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ForEach(suggestedTags) { suggestion in
              Button(action: { addTag(suggestion) }) {
                Text("+ \(suggestion.name)")
                  .font(.caption)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.gray.opacity(0.2))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
        }
      }
    }
  }
  
  private func addTagFromInput() {
    let tagName = newTagText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !tagName.isEmpty else { return }
    
    // If a tag with the same name already exists (case-insensitive), add it.
    if let existing = allTags.first(where: { $0.name.lowercased() == tagName }) {
      addTag(existing)
    } else {
      // Otherwise, create a new tag representation.
      // A temporary negative ID indicates it's a new tag to be created.
      let newTag = Tag(id: -Int64.random(in: 1...1_000_000), name: tagName)
      addTag(newTag)
    }
    newTagText = ""
  }
  
  private func addTag(_ tag: Tag) {
    if !tags.contains(where: { $0.name.lowercased() == tag.name.lowercased() }) {
      tags.append(tag)
    }
    newTagText = ""
  }
  
  private func removeTag(_ tagToRemove: Tag) {
    tags.removeAll { $0.id == tagToRemove.id && $0.name == tagToRemove.name }
  }
}

struct TagPill: View {
  let tag: Tag
  var onRemove: () -> Void
  
  var body: some View {
    HStack(spacing: 4) {
      Text(tag.name)
      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
      }
      .buttonStyle(BorderlessButtonStyle())
    }
    .font(.caption)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.accentColor.opacity(0.8))
    .foregroundColor(.white)
    .cornerRadius(10)
  }
}

