# MarkMyWord

<p align="center">
  <strong>A high-performance, keyboard-first, distraction-free Markdown reader and editor inspired by Linear's design system.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-macOS%20|%20Windows%20|%20Linux%20|%20Web-5E6AD2" alt="Platforms" />
  <img src="https://img.shields.io/badge/GFM-Spec%200.31-27C93F" alt="GFM Spec" />
  <img src="https://img.shields.io/badge/License-Proprietary-blue" alt="License" />
</p>

---

## 📖 Overview

**MarkMyWord** (package: `mark_my_words`) is a desktop Markdown application engineered for developers, engineering managers, researchers, and technical writers who read and write technical specifications, RFCs, and documentation daily.

Traditional desktop Markdown readers are frequently bloated web-wrapper applications with slow cold-boot times, heavy memory consumption (250MB–500MB RAM), and non-native window chrome. **MarkMyWord** is built natively with **Flutter & Dart**, delivering:

- **Sub-150ms Cold Launch**: Near-instantaneous application startup.
- **Ultra-Lean Resource Usage**: Typical baseline memory footprint of ~25MB–40MB.
- **Linear Design System Aesthetics**: Dark obsidian surfaces (`#08090a`, `#12141a`), 1px subtle borders, accent glows (`#5e6ad2`), and refined micro-interactions.
- **Deep macOS Native Integration**: Seamless Cocoa titlebar merging with traffic lights, LaunchServices default viewer registration, Finder drag-and-drop file opening, and one-click `/Applications` deployment.
- **Keyboard-First Workflow**: Full application control through a global Command Palette (`⌘K`) and single-key shortcuts.

---

## 💻 Supported Operating Systems & Platforms

MarkMyWord is built with cross-platform architecture in Flutter, providing first-class desktop experiences and flexible cross-platform compatibility:

| Operating System / Platform | Status & Tier | Minimum OS Version | Supported Architectures | Native Integrations & Capabilities |
| :--- | :---: | :--- | :--- | :--- |
| **macOS** | **Tier 1 (Primary)** | **macOS 11.0 (Big Sur)** or newer | Apple Silicon (`arm64`: M1/M2/M3/M4) & Intel (`x86_64`) Universal Binary | • Transparent titlebar with native traffic lights<br>• Default Markdown Viewer registration (`.md`, `.markdown`, `.mdown`, `.mkdn`)<br>• Finder double-click and "Open With" file handling<br>• Drag-to-`/Applications` installation wizard with fallback to `~/Applications`<br>• Native DMG installer package (`scripts/create_dmg.sh`)<br>• Security-scoped Cocoa file access fallback |
| **Windows** | **Tier 2 (Supported)** | **Windows 10 / Windows 11** (64-bit) | `x64` | • Native Win32 desktop runner<br>• Complete `Ctrl`-based keyboard shortcut map<br>• Local file picker integration (`.md`, `.markdown`, `.txt`)<br>• Split view & full-featured GFM + Mermaid rendering |
| **Linux** | **Tier 2 (Supported)** | **Ubuntu 20.04+**, Fedora 36+, Debian 11+, Arch Linux | `x64` / `arm64` | • Native GTK 3+ desktop runner<br>• Complete keyboard navigation and Command Palette<br>• Native file dialog integration |
| **Web** | **Supported** | Modern evergreen browsers (Chrome, Edge, Safari, Firefox) | All | • Responsive Web / PWA layout<br>• Web App Manifest and progressive web app icons included |
| **Mobile (iOS & Android)** | **Compatible** | iOS 13.0+ / Android 5.0+ (API 21+) | `arm64`, `armv7`, `x86_64` | • Touch-optimized scrolling and responsive layout |

> **Note on macOS Compatibility**: MarkMyWord has been thoroughly verified on **macOS 12 Monterey**, **macOS 13 Ventura**, **macOS 14 Sonoma**, and **macOS 15 Sequoia**.

---

## ✨ Features & Functionality

### 1. Triple View Modes
Seamlessly switch perspectives depending on your workflow:
- **Reader Mode (`⌘1` / `Ctrl+1`)**: Distraction-free, centered prose layout calibrated for extended reading. Customize reading widths (**Compact: 640px**, **Standard: 760px**, **Wide: 960px**) and typography scales (**Small: 13.5px**, **Medium: 15px**, **Large: 16.5px**). Includes a top reading progress indicator bar.
- **Split View (`⌘2` / `Ctrl+2`)**: Side-by-side workflow featuring an editable monospaced Markdown editor on the left and live GFM rendering on the right. Clicking section headings in the outline automatically navigates and moves the editor cursor to the relevant heading line.
- **Source Mode (`⌘3` / `Ctrl+3`)**: Full-screen raw markdown text editor with monospaced JetBrains Mono typography for distraction-free authoring.

### 2. Command Palette (`⌘K` / `Ctrl+K`)
A modal fuzzy-search palette allowing keyboard-driven control:
- Quick jump between recently opened and sample documents.
- Open local Markdown files via native file pickers (`⌘O`).
- Toggle between Reader, Split, and Source view modes.
- Toggle navigation sidebar (`⌘B`) and table of contents outline (`⌘T`).
- Toggle between Obsidian Dark and Clean Light themes (`⌘D`).
- Copy the entire Markdown document to the system clipboard (`⌘C`).
- Trigger macOS installation to `/Applications` or set MarkMyWord as the system default reader.

### 3. Interactive Outline & Table of Contents (`⌘T` / `Ctrl+T`)
- **Automatic Heading Extraction**: Scans headings (H1 through H6) with nested visual indentation.
- **Active Section Scrollspy**: Automatically tracks reader scroll position and highlights the section currently in view.
- **Smooth Navigation**: Click any outline entry to trigger a cubic bezier scroll animation directly to that section.
- **Dual-Pane Synchronization**: In Split Mode, selecting an outline item navigates the rendered preview and synchronizes the source editor caret.

### 4. GitHub Flavored Markdown (GFM Spec 0.31) Engine
Full fidelity rendering for modern Markdown documents:
- **Task Lists & Checkboxes**: Interactive checkboxes (`- [ ]`, `- [x]`).
- **Code Blocks**: Formatted syntax blocks with language tags, line numbering, and a 1-click clipboard copy button.
- **GitHub Alert Callouts**: Styled visual banners for `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]`.
- **GFM Tables**: Crisp borders, custom cell padding, and header contrast.
- **Typography**: Formatted blockquotes with accent borders, autolinks, strikethrough, and custom horizontal rules.

### 5. Mermaid Vector Diagram Engine
Native inline diagram visualization without external web services:
- **Diagram Types**: Flowcharts (`flowchart TD`, `flowchart LR`, `graph`), Sequence diagrams (`sequenceDiagram`), and State diagrams (`stateDiagram-v2`).
- **Dual Diagram Display**: Toggle instantly between the rendered visual diagram canvas and the raw Mermaid source definition.
- **Source Export**: Dedicated 1-click button to copy diagram source code.

### 6. Streaming Performance & Reading Analytics
- **Large Document Streaming**: Handles large multi-megabyte Markdown specifications (e.g. 4+ MB documents with thousands of lines) smoothly with asynchronous chunked ingestion and frosted shimmer loaders.
- **Real-Time Document Metrics**: Live status bar displaying total word count, line count, UTF-8 encoding badge, GFM specification compliance, and calculated reading time (calibrated at 220 words per minute).

### 7. Deep macOS Integration & Packaging
- **Default Application Association**: Register MarkMyWord as the default handler for `net.daringfireball.markdown` and `public.markdown` via macOS LaunchServices.
- **LaunchServices Event Stream**: Open Markdown files from Finder via double-click, drag-and-drop, or `Open With -> MarkMyWord`.
- **CLI Ingestion**: Launch files directly from the terminal (e.g. `open -a MarkMyWord spec.md`).
- **Move to /Applications Wizard**: Interactive dialog allowing one-click movement of the app bundle from disk images or Downloads into `/Applications` (with automatic fallback to `~/Applications`).
- **DMG Creation Script**: Build compressed, production-ready disk images with drag-and-drop symlinks using native `hdiutil` (`scripts/create_dmg.sh`).

---

## ⌨️ Keyboard Shortcuts Reference

| Shortcut (macOS) | Shortcut (Win/Linux) | Action / Command |
| :--- | :--- | :--- |
| <kbd>⌘</kbd> + <kbd>K</kbd> | <kbd>Ctrl</kbd> + <kbd>K</kbd> | Open Command Palette |
| <kbd>⌘</kbd> + <kbd>O</kbd> | <kbd>Ctrl</kbd> + <kbd>O</kbd> | Open Local File (`.md`, `.markdown`, `.txt`) |
| <kbd>⌘</kbd> + <kbd>1</kbd> | <kbd>Ctrl</kbd> + <kbd>1</kbd> | Switch to **Reader Mode** |
| <kbd>⌘</kbd> + <kbd>2</kbd> | <kbd>Ctrl</kbd> + <kbd>2</kbd> | Switch to **Split View** (Editor + Preview) |
| <kbd>⌘</kbd> + <kbd>3</kbd> | <kbd>Ctrl</kbd> + <kbd>3</kbd> | Switch to **Source Mode** |
| <kbd>⌘</kbd> + <kbd>B</kbd> | <kbd>Ctrl</kbd> + <kbd>B</kbd> | Toggle Navigation Sidebar |
| <kbd>⌘</kbd> + <kbd>T</kbd> | <kbd>Ctrl</kbd> + <kbd>T</kbd> | Toggle Table of Contents (Outline) |
| <kbd>⌘</kbd> + <kbd>D</kbd> | <kbd>Ctrl</kbd> + <kbd>D</kbd> | Toggle Dark / Light Theme |
| <kbd>⌘</kbd> + <kbd>P</kbd> | <kbd>Ctrl</kbd> + <kbd>P</kbd> | Focus File Search in Sidebar |
| <kbd>Esc</kbd> | <kbd>Esc</kbd> | Dismiss Command Palette / Modals |

---

## 📁 Project Structure

```text
mark_my_words/
├── lib/
│   ├── data/
│   │   └── sample_documents.dart     # Sample documents (Linear spec, architecture, benchmarks)
│   ├── models/
│   │   └── document_model.dart       # DocumentItem, HeadingItem, metrics models
│   ├── services/
│   │   └── system_service.dart       # macOS MethodChannel & system integration service
│   ├── theme/
│   │   └── linear_theme.dart         # Obsidian dark & light color palette tokens
│   ├── widgets/
│   │   ├── command_palette.dart      # Fuzzy command search modal (⌘K)
│   │   ├── install_dialogs.dart      # Move to /Applications & Default Viewer dialogs
│   │   ├── linear_loader.dart        # Laser progress shimmers & loading overlays
│   │   ├── markdown_view.dart        # GFM renderer, code blocks, heading registry
│   │   └── mermaid_widget.dart       # Mermaid vector diagram renderer & source toggle
│   └── main.dart                     # App shell, titlebar, split layout, sidebar, TOC
├── macos/
│   ├── Runner/
│   │   ├── AppDelegate.swift         # Finder openFile & CLI argument routing
│   │   ├── MainFlutterWindow.swift   # Cocoa window styling, LaunchServices channel
│   │   └── Info.plist                # Document type definitions (.md, .markdown)
├── scripts/
│   └── create_dmg.sh                 # Native macOS DMG installer builder script
├── test/
│   ├── system_integration_test.dart  # MethodChannel and native system dialog tests
│   └── widget_test.dart              # UI view mode, command palette, and widget tests
└── pubspec.yaml                      # Project dependencies and Flutter configuration
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.10.0` or higher)
- [Dart SDK](https://dart.dev/get-dart) (`^3.10.0` or higher)
- **macOS Build**: Xcode 14+ and CocoaPods
- **Windows Build**: Visual Studio 2022 with Desktop development with C++
- **Linux Build**: Clang, CMake, GTK development headers (`libgtk-3-dev`)

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/mark_my_words.git
   cd mark_my_words
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on macOS Desktop**:
   ```bash
   flutter run -d macos
   ```

4. **Run on other platforms**:
   ```bash
   # Windows Desktop
   flutter run -d windows

   # Linux Desktop
   flutter run -d linux

   # Web Browser
   flutter run -d chrome
   ```

---

## 📦 Building & Packaging

### macOS DMG Installer

To build a standalone macOS application bundle and generate a compressed DMG installer with a drag-and-drop `/Applications` symlink:

```bash
# 1. Build the release macOS app bundle
flutter build macos --release

# 2. Package into a compressed DMG installer
./scripts/create_dmg.sh
```

The resulting disk image is generated at:
```text
build/MarkMyWord-Installer.dmg
```

### Running Test Suite

Verify that all unit and widget tests pass:

```bash
flutter test
```

---

## 🎨 Design Philosophy

MarkMyWord is built on three core tenets:

1. **Speed & Zero Friction**: Every operation should execute within milliseconds. Documents open without blocking the UI thread, and file switching is fluid.
2. **Obsidian Clarity**: Designed following the Linear design system, the interface stays out of your way. Visual emphasis is placed on your document content, with typography tuned for contrast and readability.
3. **Native Desktop Synergy**: Rather than acting as an isolated web view, MarkMyWord integrates deeply into the host OS with native window controls, system default associations, and keyboard-driven ergonomics.
