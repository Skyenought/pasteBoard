//
//  Helper.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//

// File: Utils/Helper.swift

import Foundation // Ensure Foundation is imported for JSONSerialization

func detectContentType(from string: String) -> DisplayMode {
    let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)

    // 1. Initial Checks for Trivial Cases:
    // If the string is empty or very short, it"s unlikely to be structured content.
    guard !trimmedString.isEmpty else {
        return .plain
    }
    // A slightly higher threshold (e.g., 10 characters) can prevent misclassification
    // of simple words or short phrases as code/markdown.
    if trimmedString.count < 10 {
        return .plain
    }

    // 2. Detect Specific Structured Formats (e.g., JSON, XML):
    // These formats often have strict structural delimiters, making them easy to identify early.

    // JSON Detection: Checks for curly/square brace encapsulation and attempts basic parsing.
    if (trimmedString.hasPrefix("{") && trimmedString.hasSuffix("}")) ||
       (trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]")) {
        if let data = trimmedString.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data, options: [])) != nil {
            return .code // Valid JSON is considered "code"
        }
    }

    // XML/HTML Detection: Checks for common tag patterns.
    if trimmedString.hasPrefix("<") && trimmedString.contains("</") && trimmedString.hasSuffix(">") {
        return .code
    }
    
    // Shebang Line Detection (for scripts like #!/bin/bash)
    if trimmedString.hasPrefix("#!") {
        return .code
    }

    // 3. Markdown Detection: Look for common Markdown syntax elements.
    // Prioritize patterns that are strong indicators of Markdown.
    let markdownIndicators: [String] = [
        "```", // Code block fences (most reliable indicator)
        "\n# ", "\n## ", "\n### ", "\n#### ", "\n##### ", "\n###### ", // Headers (with newline for multi-line context)
        "\n* ", "\n- ", "\n+ ", // Unordered list items (with newline)
        "\n1. ", "\n2. ", "\n3. ", // Ordered list items (with newline)
        "---", "___", "***", // Horizontal rules (e.g., `***` for bold/italic)
        "](", // Common link syntax: `[text](url)`
        "|", // Table syntax, e.g., `| Header |`
        "`", // Inline code
    ]
    
    // Check for strong markdown indicators anywhere in the string.
    if markdownIndicators.contains(where: { trimmedString.contains($0) }) {
        return .markdown
    }
    
    // Check for markdown indicators at the very beginning of the string.
    if trimmedString.hasPrefix("#") || trimmedString.hasPrefix("- ") ||
       trimmedString.hasPrefix("* ") || trimmedString.hasPrefix("1. ") {
        return .markdown
    }

    // 4. General Programming Code Detection: Keywords and symbol density.

    // Common programming keywords across various languages (Swift, Python, JS, Java, C#, etc.).
    let programmingKeywords: [String] = [
        // Swift/Obj-C specific
        "import", "func", "class", "struct", "let", "var", "enum", "extension", "protocol", "init", "self", "super", "override", "public", "private", "internal", "fileprivate", "open", "weak", "unowned", "await", "throw", "try", "catch", "guard", "defer", "inout", "didSet", "willSet",
        // General programming
        "function", "return", "if", "else", "for", "while", "switch", "case", "break", "continue", "printf", "console.log", "System.out.println", "namespace", "using", "main(", "void", "static", "interface", "abstract", "extends", "implements", "this", "new", "delete", "const", "var", "null", "undefined",
    ]
    
    // Check if the text contains a reasonable number of programming keywords.
    // Using a lowercased comparison to be case-insensitive.
    let lowercasedTrimmedString = trimmedString.lowercased()
    let keywordMatchCount = programmingKeywords.filter { lowercasedTrimmedString.contains($0.lowercased()) }.count
    if keywordMatchCount >= 3 { // Requiring at least 3 distinct matches to increase confidence
        return .code
    }

    // Check for high density of common programming symbols.
    // Expanded set of symbols that are more indicative of code than plain text.
    let codeSymbols: Set<Character> = [
        "{", "}", "(", ")", "[", "]", ";", ",", ".", ":", "?", "!",
        "<", ">", "=", "+", "-", "*", "/", "%", "&", "|", "^", "~",
        "`", "@", "#", "$", "_",
    ]
    let symbolCount = trimmedString.filter { codeSymbols.contains($0) }.count
    
    // If a significant percentage of characters are programming symbols, classify as code.
    // This threshold can be fine-tuned. 7% is a common heuristic for code vs. plain text.
    if trimmedString.count > 0 && Double(symbolCount) / Double(trimmedString.count) > 0.07 {
        return .code
    }

    // Check for common code comment patterns (multi-line or single-line with newline prefix)
    if (trimmedString.contains("/*") && trimmedString.contains("*/")) || trimmedString.contains("\n//") {
        return .code
    }

    // 5. Fallback: If no specific type is confidently detected, treat as plain text.
    return .plain
}
