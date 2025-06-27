//
//  Helper.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//

func detectContentType(from string: String) -> DisplayMode {
  let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
  
  if trimmedString.count < 3 { return .plain }
  
  let markdownPatterns = ["\n#", "\n##", "```", "\n* ", "\n- ", "\n1. "]
  if markdownPatterns.contains(where: { trimmedString.contains($0) }) ||
      trimmedString.hasPrefix("#") || trimmedString.hasPrefix("- ") || trimmedString.hasPrefix("* ") {
    return .markdown
  }
  
  let codeSymbols: Set<Character> = ["{", "}", ";", ":", "<", ">", "/", "(", ")"]
  let symbolCount = trimmedString.filter { codeSymbols.contains($0) }.count
  if Double(symbolCount) / Double(trimmedString.count) > 0.04 { return .code }
  
  if (trimmedString.hasPrefix("{") && trimmedString.hasSuffix("}")) || (trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]")) { return .code }
  
  let codeKeywords = ["import ", "func ", "class ", "struct ", "let ", "var ", "const "]
  if codeKeywords.contains(where: { trimmedString.contains($0) }) { return .code }
  
  return .plain
}
