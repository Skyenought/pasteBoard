//
//  View+Extensions.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//
import SwiftUI

extension View {
  func onContinuousHover(cursor: NSCursor) -> some View {
    self.onHover { inside in
      if inside {
        cursor.push()
      } else {
        NSCursor.pop()
      }
    }
  }
}
