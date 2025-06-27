//
//  TagFilterPillView.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//

import SwiftUI

// ==========================================================
// New View for Tag Filtering Pills
// ==========================================================
struct TagFilterPillView: View {
  let tag: Tag
  let isSelected: Bool
  
  var body: some View {
    Text(tag.name)
      .font(.caption)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
      .foregroundColor(isSelected ? .white : .primary)
      .cornerRadius(12)
      .contentShape(Rectangle())
  }
}
