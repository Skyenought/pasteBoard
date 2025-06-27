# PasteBoard - Smart macOS Clipboard Management Tool

[中文](./readme.md)

## 🚀 Project Overview

PasteBoard is an intelligent clipboard history management tool designed specifically for macOS. It automatically records copied text, images, and file paths, offering powerful search, filtering, editing, and preview functionalities to help you efficiently manage and utilize your clipboard content. Whether you're a developer, designer, or regular user, PasteBoard aims to make your daily operations more convenient.

## ✨ Key Features

* **Comprehensive Clipboard History**: Automatically saves copied text, images, and file paths.
* **Intelligent Content Preview & Rendering**:
  * Supports plain text, syntax-highlighted code (various themes), and Markdown rendering.
  * The application intelligently detects content types (code, Markdown, plain text) and selects the optimal display mode.
  * Provides a dedicated detailed preview window, supporting full-screen viewing and manual switching of display modes.
* **Efficient Search & Filtering**:
  * Supports full-text search by custom title, content, or tags.
  * Offers "All" and "Favorites" modes for quick switching of history views.
  * **New**: Supports precise date range filtering for history records, making it easy to find clipboard content from specific periods.
  * **New**: Filter by tags to quickly locate specific categories of clipboard content, with support for multi-tag selection.
* **Personalized Management**:
  * Add custom titles to important clipboard items for easier identification.
  * Mark frequently used items as "Favorites" for quick access and to protect them from bulk deletion.
  * Add and manage tags for items, enabling more granular categorization and organization.
* **Convenient Operations**:
  * Global hotkey `⌘ + ⌥ + V` to quickly bring up the main application window, boosting productivity.
  * One-click copy of any historical item back to the system clipboard.
  * Supports deleting individual records, or bulk deleting all non-favorite records (supports holding `Option` key for direct deletion).
  * Integrated tag management interface allows adding, renaming, and deleting tags; intelligently checks if a tag is in use by other records before deletion, providing user-friendly prompts.
* **User Interface**:
  * Clean and intuitive SwiftUI interface, offering a smooth user experience.
  * Supports switching between system, light, or dark mode to suit user preferences.

## 📸 Screenshots (To be added)
<!-- Insert your app screenshots here, e.g.: -->
<!-- ![Main Window](screenshots/main_window.png) -->
<!-- ![Preview Window](screenshots/preview_window.png) -->
<!-- ![Tag Management](screenshots/tag_management.png) -->

## 🛠️ Technology Stack

* **SwiftUI**: For building modern and responsive user interfaces.
* **AppKit**: For implementing macOS-specific system-level functionalities such as clipboard monitoring, global hotkeys, NSImage handling, etc.
* **GRDB.swift**: A powerful and type-safe SQLite database wrapper for efficient data persistence and querying.
* **MarkdownUI**: For rendering Markdown formatted text within SwiftUI views.
* **Highlightr**: For enabling code syntax highlighting.
* **Quartz (QuickLook)**: For potential future expansion of file path content previews.
* **Carbon.HIToolbox**: For registering and managing global system hotkeys.

## ⚙️ Installation & Running

1. **Clone the repository**:
    First, clone the project repository to your local machine using Git:

    ```bash
    git clone https://github.com/your-username/pasteboard.git
    cd pasteboard
    ```

2. **Open the project**:
    Open the `pasteboard.xcodeproj` file in Xcode.
3. **Install dependencies**:
    This project uses Swift Package Manager (SPM) for all external dependencies (e.g., GRDB.swift, MarkdownUI, Highlightr). Xcode will automatically resolve and download the necessary packages. If you encounter network issues or resolution failures, you can try selecting `File > Packages > Resolve Package Versions` from the Xcode menu.
4. **Build and Run**:
    Select your macOS device (usually "My Mac") as the run target, then click the Run button (▶️) in Xcode.

    **Important Notes**:
    * **Accessibility Permissions**: For the global hotkey `⌘ + ⌥ + V` to function, the application requires "Accessibility" permissions. The app will attempt to guide you to "System Settings" > "Privacy & Security" > "Accessibility" to grant these permissions upon first launch. It is crucial to enable this, otherwise the hotkey will not work.
    * **Database Location**: Clipboard history data is persistently stored in a specific location within your user directory: `~/Documents/pasteBoard/history.sqlite`.

## 🚀 Usage Guide

1. **Launch the App**: Once launched, the app will automatically monitor your clipboard in the background and save copied content to its history.
2. **Bring Up the Main Window**:
    * You can open the main window by clicking the app icon in the Dock.
    * Alternatively, press the global hotkey `⌘ + ⌥ + V` at any time to quickly bring up the application.
3. **Browse History**: The main interface displays all your copied history records in a list.
4. **Search and Filter**:
    * **Search Bar**: Use the search bar at the top to perform fuzzy searches based on item's custom title, original content, or associated tags.
    * **Favorites/All Filter**: In the bottom toolbar, switch between displaying all history records (`All`) or only your favorited items (`Favorites`).
    * **Date Filter**: Click the `calendar` icon in the bottom toolbar to bring up a date picker. You can select a date range to filter and display clipboard history from specific time periods.
    * **Tag Filter**: Below the search bar, all created tags (if any) will be displayed. Click any tag pill to quickly filter items that include that tag. Clicking an already selected tag will clear the filter.
5. **Interact with Clipboard Items**:
    * **Copy to Clipboard**: Click the `doc.on.doc` icon (copy icon) on the right of a list item to re-copy its content to the system clipboard.
    * **Favorite/Unfavorite**: Click the `star` icon to favorite or unfavorite an item. Favorited items will not be deleted by the "Clear Non-Favorites" operation.
    * **Delete Item**: Click the `trash` icon (trash can icon) to delete an item. To prevent accidental deletion, a confirmation prompt will appear by default. If you hold down the `⌥ (Option)` key while clicking, it will bypass the confirmation and delete directly.
    * **Preview Detailed Content**: Clicking any item in the list will open a new, separate window with a detailed preview of that item.
    * **Edit Item**: From either the main list or the preview window, click the `Edit Item...` button to enter edit mode.
        * In edit mode, you can set a **custom title** for the item, choose its **display mode** (Auto, Plain Text, Code, Markdown), and **add or remove tags**.
6. **Manage Tags**:
    * Below the search bar in the main interface, click the `gearshape` icon to enter the tag management interface.
    * Here, you can add new tags, rename existing ones, or delete tags you no longer need. When deleting a tag, the system will check if it's currently in use by other records, ensuring you don't accidentally remove an important tag.
7. **Clear All Non-Favorite History**:
    At the bottom of the main list, if the current filter mode is `All` and no search or tag filter is active, you will see a `Clear` button. Clicking it will delete all history records not marked as favorites (a confirmation prompt will appear).

## 🤝 Contributing

Contributions in all forms are welcome! If you have any ideas, bug reports, feature suggestions, or code improvements, please feel free to submit them via GitHub Issues or Pull Requests.

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file in the project root for more details.
