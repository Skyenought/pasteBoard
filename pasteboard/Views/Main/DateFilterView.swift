//
//  DateFilterView.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//
import SwiftUI

// ==========================================================
// New View for the Date Filter Popover
// ==========================================================
struct DateFilterView: View {
  @EnvironmentObject private var viewModel: ClipboardViewModel
  @State private var isShowingPopover = false
  
  // Local state for the popover's date pickers
  @State private var startDate: Date
  @State private var endDate: Date
  
  init() {
    // Initialize local state with the ViewModel's current state
    _startDate = State(initialValue: Calendar.current.startOfDay(for: Date()))
    _endDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date())
  }
  
  var body: some View {
    Button {
      // When opening the popover, sync local state with viewmodel
      startDate = viewModel.startDateFilter ?? Calendar.current.startOfDay(for: Date())
      endDate = viewModel.endDateFilter ?? Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? Date()
      isShowingPopover = true
    } label: {
      Image(systemName: "calendar")
      // Highlight the button if the date filter is active
        .foregroundColor(viewModel.isDateFilterActive ? .accentColor : .primary)
    }
    .help("按日期筛选")
    .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
      VStack(spacing: 16) {
        Text("选择日期范围")
          .font(.headline)
        
        // 修改日期选择器显示格式
        DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
          .environment(\.locale, Locale(identifier: "zh_CN"))
          .environment(\.calendar, Calendar(identifier: .gregorian))
        
        DatePicker("结束日期", selection: $endDate, in: startDate..., displayedComponents: .date)
          .environment(\.locale, Locale(identifier: "zh_CN"))
          .environment(\.calendar, Calendar(identifier: .gregorian))
        
        
        HStack {
          Button("清除") {
            viewModel.clearDateFilter()
            isShowingPopover = false
          }
          
          Spacer()
          
          Button("应用") {
            viewModel.setDateFilter(start: startDate, end: endDate)
            isShowingPopover = false
          }
          .keyboardShortcut(.defaultAction)
        }
      }
      .padding()
      .frame(width: 280)
    }
  }
}
