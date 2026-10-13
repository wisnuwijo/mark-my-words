import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/sample_documents.dart';
import 'models/document_model.dart';
import 'services/system_service.dart';
import 'theme/linear_theme.dart';
import 'widgets/command_palette.dart';
import 'widgets/install_dialogs.dart';
import 'widgets/linear_loader.dart';
import 'widgets/markdown_view.dart';

void main([List<String> args = const []]) {
  runApp(MarkMyWordsApp(initialArgs: args));
}

class MarkMyWordsApp extends StatefulWidget {
  final List<String> initialArgs;
  const MarkMyWordsApp({super.key, this.initialArgs = const []});

  @override
  State<MarkMyWordsApp> createState() => _MarkMyWordsAppState();
}

class _MarkMyWordsAppState extends State<MarkMyWordsApp> {
  bool _isDark = true;

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarkMyWord',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? LinearTheme.getDarkTheme() : LinearTheme.getLightTheme(),
      home: MainWindowScreen(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
        initialArgs: widget.initialArgs,
      ),
    );
  }
}

enum ViewMode { reader, split, source }

class MainWindowScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final List<String> initialArgs;

  const MainWindowScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.initialArgs = const [],
  });

  @override
  State<MainWindowScreen> createState() => _MainWindowScreenState();
}

class _MainWindowScreenState extends State<MainWindowScreen> {
  late List<DocumentItem> _documents;
  late DocumentItem _activeDoc;
  ViewMode _viewMode = ViewMode.reader;

  bool _isSidebarOpen = true;
  bool _isTocOpen = true;
  bool _isLoading = false;
  String _loadingTitle = '';
  String _loadingMeta = '';

  ContentWidthMode _widthMode = ContentWidthMode.standard;
  FontSizeScale _fontScale = FontSizeScale.medium;

  final TextEditingController _splitEditController = TextEditingController();
  final TextEditingController _searchFilterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  String _sidebarFilter = '';
  StreamSubscription<String>? _fileOpenedSub;
  final Map<String, GlobalKey> _headingKeys = {};
  late final HeadingKeyRegistry _headingRegistry = HeadingKeyRegistry(_headingKeys);
  String? _activeHeadingId;

  @override
  void initState() {
    super.initState();
    _documents = SampleDocuments.getInitialDocuments();
    _activeDoc = _documents.first;
    _splitEditController.text = _activeDoc.content;

    _scrollController.addListener(_onScroll);
    _searchFilterController.addListener(() {
      setState(() {
        _sidebarFilter = _searchFilterController.text.toLowerCase();
      });
    });

    _splitEditController.addListener(() {
      if (_viewMode == ViewMode.split || _viewMode == ViewMode.source) {
        setState(() {
          _activeDoc.content = _splitEditController.text;
        });
      }
    });

    // Initialize native macOS system service & live file open listener
    SystemService.initialize();
    _fileOpenedSub = SystemService.onFileOpened.listen((path) {
      _openExternalFilePath(path);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialOpenedFileAndPrompts();
    });
  }

  @override
  void dispose() {
    _fileOpenedSub?.cancel();
    _scrollController.dispose();
    _splitEditController.dispose();
    _searchFilterController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialOpenedFileAndPrompts() async {
    // 1. If launched with a file from Finder or CLI argument
    String? initialFile;
    if (widget.initialArgs.isNotEmpty) {
      final candidate = widget.initialArgs.first.trim();
      if (!candidate.startsWith('-') && candidate.isNotEmpty) {
        initialFile = candidate;
      }
    }
    initialFile ??= await SystemService.getInitialOpenedFile();

    if (initialFile != null && initialFile.isNotEmpty) {
      await _openExternalFilePath(initialFile);
    }

    // 2. Check if running outside /Applications
    final isApps = await SystemService.isRunningFromApplications();
    final shouldPromptApps =
        await SystemService.getShouldPromptMoveToApplications();
    if (!isApps && shouldPromptApps && mounted) {
      await MoveToApplicationsDialog.show(context, isDark: widget.isDark);
      return;
    }

    // 3. Check if default markdown viewer
    final isDefault = await SystemService.isDefaultMarkdownViewer();
    final shouldPromptDefault =
        await SystemService.getShouldPromptDefaultViewer();
    if (!isDefault && shouldPromptDefault && mounted) {
      await DefaultViewerDialog.show(context, isDark: widget.isDark);
    }
  }

  Future<void> _openExternalFilePath(String rawPath) async {
    try {
      var path = rawPath.trim();
      if (path.isEmpty) return;

      // Handle file:// URIs passed by macOS LaunchServices
      if (path.startsWith('file://')) {
        final uri = Uri.tryParse(path);
        if (uri != null) {
          path = uri.toFilePath();
        }
      }

      String? content;
      int fileSize = 0;

      // Attempt 1: Direct file read via dart:io
      final file = File(path);
      try {
        if (await file.exists()) {
          fileSize = await file.length();
          content = await file.readAsString();
        }
      } catch (e) {
        debugPrint('Direct file read error for $path: $e');
      }

      // Attempt 2: Native Cocoa reader with security scope fallback
      if (content == null) {
        content = await SystemService.readFile(path);
        if (content != null) {
          fileSize = content.length;
        }
      }

      if (content == null) {
        debugPrint('Failed to load markdown content from: $path');
        return;
      }
      final validContent = content;

      final fileName = path.split(Platform.pathSeparator).isNotEmpty
          ? path.split(Platform.pathSeparator).last
          : 'Document.md';

      final sizeStr = fileSize > 1024 * 1024
          ? '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(fileSize / 1024).toStringAsFixed(1)} KB';

      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _loadingTitle = 'Opening $fileName...';
        _loadingMeta = '$sizeStr • External File Stream';
      });

      await Future.delayed(const Duration(milliseconds: 160));

      final existingIndex = _documents.indexWhere((d) => d.filePath == path);
      if (existingIndex >= 0) {
        final existingDoc = _documents[existingIndex];
        existingDoc.content = validContent;
        if (!mounted) return;
        setState(() {
          _activeDoc = existingDoc;
          _splitEditController.text = validContent;
          _isLoading = false;
          _scrollProgress = 0.0;
          _headingKeys.clear();
          _activeHeadingId = null;
        });
      } else {
        final newDoc = DocumentItem(
          id: 'external_${DateTime.now().millisecondsSinceEpoch}',
          title: fileName,
          folder: 'Finder',
          tag: 'Opened',
          isLarge: fileSize > 100 * 1024,
          filePath: path,
          content: validContent,
        );
        if (!mounted) return;
        setState(() {
          _documents.insert(0, newDoc);
          _activeDoc = newDoc;
          _splitEditController.text = validContent;
          _isLoading = false;
          _scrollProgress = 0.0;
          _headingKeys.clear();
          _activeHeadingId = null;
        });
      }

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } catch (e) {
      debugPrint('Error opening external file $rawPath: $e');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      setState(() {
        _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    }
    _updateActiveHeadingOnScroll();
  }

  void _updateActiveHeadingOnScroll() {
    final headings = _extractHeadings();
    if (headings.isEmpty) return;

    if (_scrollController.hasClients && _scrollController.position.pixels <= 30) {
      if (_activeHeadingId != headings.first.id) {
        setState(() => _activeHeadingId = headings.first.id);
      }
      return;
    }

    String? currentActiveId;
    for (final item in headings) {
      final key = _headingKeys[item.id] ?? _headingKeys['heading_idx_${item.index}'];
      final context = key?.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.attached) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dy <= 160) {
            currentActiveId = item.id;
          }
        }
      }
    }

    if (currentActiveId != null && currentActiveId != _activeHeadingId) {
      setState(() => _activeHeadingId = currentActiveId);
    }
  }

  void _scrollToHeading(HeadingItem item) {
    setState(() {
      _activeHeadingId = item.id;
    });

    final key = _headingKeys[item.id] ??
        _headingKeys['heading_idx_${item.index}'] ??
        _headingKeys['heading_${item.index}'];

    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.05,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else if (_scrollController.hasClients) {
      // Fallback: estimate scroll offset by heading line proportion
      final lines = _activeDoc.content.split('\n');
      final lineIndex = lines.indexWhere((l) => l.trim().contains(item.text));
      if (lineIndex >= 0 && lines.isNotEmpty) {
        final ratio = lineIndex / lines.length;
        final targetOffset = (_scrollController.position.maxScrollExtent * ratio).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
      }
    }

    // In split mode, also synchronize editor cursor to heading line
    if (_viewMode == ViewMode.split) {
      final lines = _splitEditController.text.split('\n');
      int charOffset = 0;
      for (final line in lines) {
        if (line.trim().contains(item.text)) {
          _splitEditController.selection = TextSelection.collapsed(
            offset: charOffset.clamp(0, _splitEditController.text.length),
          );
          break;
        }
        charOffset += line.length + 1;
      }
    }
  }

  // Document Switching with Subtle Linear Loading Feedback
  void _switchDocument(DocumentItem doc) {
    if (_activeDoc.id == doc.id) return;

    setState(() {
      _isLoading = true;
      _loadingTitle = 'Streaming ${doc.title}...';
      _loadingMeta = doc.isLarge
          ? '${doc.approximateSizeStr} • 32,800 tokens'
          : '${doc.approximateSizeStr} • ${doc.wordCount} words';
    });

    final delay = doc.isLarge ? 480 : 160;

    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _activeDoc = doc;
        _splitEditController.text = doc.content;
        _scrollProgress = 0.0;
        _headingKeys.clear();
        _activeHeadingId = null;
      });

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted) setState(() => _isLoading = false);
      });
    });
  }

  // Open Local File on Mac via Native File Picker (⌘O)
  Future<void> _openLocalFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final path = files.first.path!;
        final file = File(path);
        final fileName = files.first.name;
        final fileSize = await file.length();
        final content = await file.readAsString();

        final sizeStr = fileSize > 1024 * 1024
            ? '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(fileSize / 1024).toStringAsFixed(1)} KB';

        setState(() {
          _isLoading = true;
          _loadingTitle = 'Opening $fileName...';
          _loadingMeta = '$sizeStr • Local file stream';
        });

        await Future.delayed(const Duration(milliseconds: 260));

        final newDoc = DocumentItem(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          title: fileName,
          folder: 'local',
          tag: 'Local',
          isLarge: fileSize > 100 * 1024,
          filePath: path,
          content: content,
        );

        setState(() {
          _documents.insert(0, newDoc);
          _activeDoc = newDoc;
          _splitEditController.text = content;
          _isLoading = false;
          _scrollProgress = 0.0;
          _headingKeys.clear();
          _activeHeadingId = null;
        });

        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  // Open Linear Command Palette (⌘K)
  void _openCommandPalette() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        return CommandPaletteDialog(
          isDark: widget.isDark,
          actions: [
            CommandPaletteAction(
              id: 'open-file',
              title: 'Open Local File on Mac...',
              group: 'Navigation',
              shortcut: '⌘O',
              icon: Icons.folder_open,
              onSelect: _openLocalFile,
            ),
            for (final doc in _documents)
              CommandPaletteAction(
                id: 'doc-${doc.id}',
                title: 'Switch to: ${doc.title}',
                group: 'Documents',
                shortcut: doc.tag,
                icon: Icons.description_outlined,
                onSelect: () => _switchDocument(doc),
              ),
            CommandPaletteAction(
              id: 'view-reader',
              title: 'Distraction-free Reader Mode',
              group: 'View',
              shortcut: '⌘1',
              icon: Icons.chrome_reader_mode_outlined,
              onSelect: () => setState(() => _viewMode = ViewMode.reader),
            ),
            CommandPaletteAction(
              id: 'view-split',
              title: 'Split View (Editor + Live Preview)',
              group: 'View',
              shortcut: '⌘2',
              icon: Icons.vertical_split,
              onSelect: () => setState(() => _viewMode = ViewMode.split),
            ),
            CommandPaletteAction(
              id: 'view-source',
              title: 'Raw Markdown Source',
              group: 'View',
              shortcut: '⌘3',
              icon: Icons.code,
              onSelect: () => setState(() => _viewMode = ViewMode.source),
            ),
            CommandPaletteAction(
              id: 'toggle-theme',
              title: 'Toggle Theme (Dark / Light)',
              group: 'Appearance',
              shortcut: '⌘D',
              icon: Icons.brightness_medium,
              onSelect: widget.onToggleTheme,
            ),
            CommandPaletteAction(
              id: 'toggle-sidebar',
              title: 'Toggle Navigation Sidebar',
              group: 'Appearance',
              shortcut: '⌘B',
              icon: Icons.view_sidebar_outlined,
              onSelect: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
            ),
            CommandPaletteAction(
              id: 'toggle-toc',
              title: 'Toggle Table of Contents Outline',
              group: 'Appearance',
              shortcut: '⌘T',
              icon: Icons.format_list_bulleted,
              onSelect: () => setState(() => _isTocOpen = !_isTocOpen),
            ),
            CommandPaletteAction(
              id: 'copy-all',
              title: 'Copy Entire Markdown Document',
              group: 'Actions',
              shortcut: '⌘C',
              icon: Icons.copy,
              onSelect: () {
                Clipboard.setData(ClipboardData(text: _activeDoc.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Markdown copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            CommandPaletteAction(
              id: 'set-default-viewer',
              title: 'Set as Default Markdown Reader...',
              group: 'macOS Integration',
              shortcut: 'Default',
              icon: Icons.check_circle_outline,
              onSelect: () =>
                  DefaultViewerDialog.show(context, isDark: widget.isDark),
            ),
            CommandPaletteAction(
              id: 'install-applications',
              title: 'Install / Move to Applications Folder...',
              group: 'macOS Integration',
              shortcut: 'Install',
              icon: Icons.folder_special_outlined,
              onSelect: () =>
                  MoveToApplicationsDialog.show(context, isDark: widget.isDark),
            ),
            CommandPaletteAction(
              id: 'open-apps-finder',
              title: 'Open /Applications in Finder',
              group: 'macOS Integration',
              shortcut: 'Finder',
              icon: Icons.folder_open,
              onSelect: SystemService.openApplicationsFolder,
            ),
          ],
        );
      },
    );
  }

  // Parse Headings for Dynamic Table of Contents
  List<HeadingItem> _extractHeadings() {
    final headings = <HeadingItem>[];
    final lines = _activeDoc.content.split('\n');
    final Map<String, int> titleOccurrences = {};
    int count = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
      if (match != null) {
        final level = match.group(1)!.length;
        final rawText = match.group(2)!.trim();
        final cleanText = rawText.replaceAll(RegExp(r'[*_`]'), '').trim();
        if (cleanText.isEmpty) continue;

        final normalized = cleanText.toLowerCase();
        final occurrence = titleOccurrences[normalized] ?? 0;
        titleOccurrences[normalized] = occurrence + 1;
        final id = 'heading_${normalized}_$occurrence';

        headings.add(HeadingItem(
          level: level,
          text: cleanText,
          id: id,
          index: count++,
        ));
      }
    }
    return headings;
  }

  // Handle Global macOS Keyboard Shortcuts
  KeyEventResult _handleGlobalKeys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCmd = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (isCmd) {
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        _openCommandPalette();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyO) {
        _openLocalFile();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyB) {
        setState(() => _isSidebarOpen = !_isSidebarOpen);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyT) {
        setState(() => _isTocOpen = !_isTocOpen);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        widget.onToggleTheme();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        setState(() => _viewMode = ViewMode.reader);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        setState(() => _viewMode = ViewMode.split);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        setState(() => _viewMode = ViewMode.source);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bgApp = widget.isDark ? LinearColors.darkBgApp : LinearColors.lightBgApp;
    final bgSurface =
        widget.isDark ? LinearColors.darkBgSurface : LinearColors.lightBgSurface;
    final borderSubtle = widget.isDark
        ? LinearColors.darkBorderSubtle
        : LinearColors.lightBorderSubtle;
    final textColor = widget.isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKeys,
      child: Scaffold(
        backgroundColor: bgApp,
        body: Column(
          children: [
            // ================= 1. macOS Window Titlebar =================
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: bgSurface,
                border: Border(bottom: BorderSide(color: borderSubtle)),
              ),
              child: Row(
                children: [
                  // Left: Window Controls, Sidebar Toggle & Breadcrumb
                  Expanded(
                    child: Row(
                      children: [
                        // Integrated space for native macOS Traffic Light buttons (Close, Min, Zoom)
                        const SizedBox(width: 68),
                        const SizedBox(width: 8),

                        // Sidebar Toggle Button (⌘B)
                        _buildIconButton(
                          icon: Icons.view_sidebar_outlined,
                          tooltip: 'Toggle Sidebar (⌘B)',
                          active: _isSidebarOpen,
                          onTap: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                        ),
                        const SizedBox(width: 10),

                        // Breadcrumb / Title (flexible with ellipsis)
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${_activeDoc.folder} / ${_activeDoc.title}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: LinearColors.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: LinearColors.accent.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Center: Segmented View Switcher (⌘1, ⌘2, ⌘3)
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? LinearColors.darkBgSurfaceElevated
                          : LinearColors.lightBgSurfaceElevated,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentedTab(
                          'Reader',
                          Icons.chrome_reader_mode_outlined,
                          _viewMode == ViewMode.reader,
                          () => setState(() => _viewMode = ViewMode.reader),
                        ),
                        _buildSegmentedTab(
                          'Split',
                          Icons.vertical_split,
                          _viewMode == ViewMode.split,
                          () => setState(() => _viewMode = ViewMode.split),
                        ),
                        _buildSegmentedTab(
                          'Source',
                          Icons.code,
                          _viewMode == ViewMode.source,
                          () => setState(() => _viewMode = ViewMode.source),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right: Stats & Controls
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? LinearColors.darkSurfaceHover
                                    : LinearColors.lightSurfaceHover,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: borderSubtle),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      size: 13, color: LinearColors.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    _activeDoc.estimatedReadingTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // TOC Toggle Button (⌘T)
                            _buildIconButton(
                              icon: Icons.format_list_bulleted,
                              tooltip: 'Toggle Table of Contents (⌘T)',
                              active: _isTocOpen,
                              onTap: () => setState(() => _isTocOpen = !_isTocOpen),
                            ),
                            const SizedBox(width: 4),

                            // Width & Font Size Menu
                            PopupMenuButton<dynamic>(
                              tooltip: 'Reading Settings',
                              icon: Icon(
                                Icons.settings_outlined,
                                size: 17,
                                color: textSecondary,
                              ),
                              color: widget.isDark
                                  ? LinearColors.darkBgSurfaceElevated
                                  : LinearColors.lightBgSurfaceElevated,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text('CONTENT WIDTH',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: LinearColors.accent)),
                                ),
                                PopupMenuItem(
                                  child: const Text('Compact (640px)'),
                                  onTap: () => setState(
                                      () => _widthMode = ContentWidthMode.compact),
                                ),
                                PopupMenuItem(
                                  child: const Text('Standard (760px)'),
                                  onTap: () => setState(
                                      () => _widthMode = ContentWidthMode.standard),
                                ),
                                PopupMenuItem(
                                  child: const Text('Wide (960px)'),
                                  onTap: () =>
                                      setState(() => _widthMode = ContentWidthMode.wide),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text('FONT SIZE',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: LinearColors.accent)),
                                ),
                                PopupMenuItem(
                                  child: const Text('Small (13.5px)'),
                                  onTap: () =>
                                      setState(() => _fontScale = FontSizeScale.small),
                                ),
                                PopupMenuItem(
                                  child: const Text('Medium (15px)'),
                                  onTap: () =>
                                      setState(() => _fontScale = FontSizeScale.medium),
                                ),
                                PopupMenuItem(
                                  child: const Text('Large (16.5px)'),
                                  onTap: () =>
                                      setState(() => _fontScale = FontSizeScale.large),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text('MACOS INTEGRATION',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: LinearColors.accent)),
                                ),
                                PopupMenuItem(
                                  child: const Text('Set as Default Markdown Reader'),
                                  onTap: () => DefaultViewerDialog.show(context,
                                      isDark: widget.isDark),
                                ),
                                PopupMenuItem(
                                  child: const Text('Install / Move to /Applications...'),
                                  onTap: () => MoveToApplicationsDialog.show(context,
                                      isDark: widget.isDark),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),

                            // Theme Toggle Button (⌘D)
                            _buildIconButton(
                              icon: widget.isDark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              tooltip: 'Toggle Theme (⌘D)',
                              onTap: widget.onToggleTheme,
                            ),
                            const SizedBox(width: 6),

                            // Command Palette Button (⌘K)
                            InkWell(
                              onTap: _openCommandPalette,
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? LinearColors.darkBgKbd
                                      : LinearColors.lightBgKbd,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: widget.isDark
                                        ? LinearColors.darkBorderDefault
                                        : LinearColors.lightBorderDefault,
                                  ),
                                ),
                                child: Text(
                                  '⌘K',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= 2. Workspace Body =================
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  if (_isSidebarOpen) _buildSidebar(),

                  // Document Viewport
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            // Linear Top Laser Loading Line
                            LinearLoaderLine(isLoading: _isLoading),

                            // Reading Progress Indicator
                            if (_viewMode == ViewMode.reader)
                              Container(
                                height: 2,
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _scrollProgress,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          LinearColors.accent,
                                          LinearColors.cyan,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Main Viewport Content
                            Expanded(child: _buildCurrentView()),
                          ],
                        ),

                        // Document Loading Frosted Overlay for Large Files
                        DocumentLoadingOverlay(
                          isVisible: _isLoading && _activeDoc.isLarge,
                          title: _loadingTitle,
                          meta: _loadingMeta,
                          isDark: widget.isDark,
                        ),
                      ],
                    ),
                  ),

                  // Right Table of Contents Outline
                  if (_isTocOpen && _viewMode != ViewMode.source) _buildTocSidebar(),
                ],
              ),
            ),

            // ================= 3. Window Status Bar =================
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: bgSurface,
                border: Border(top: BorderSide(color: borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: LinearColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GFM Spec 0.31',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_activeDoc.wordCount} words',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_activeDoc.lineCount} lines',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: _openCommandPalette,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Press ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: widget.isDark
                                      ? LinearColors.darkTextTertiary
                                      : LinearColors.lightTextTertiary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? LinearColors.darkBgKbd
                                      : LinearColors.lightBgKbd,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: widget.isDark
                                        ? LinearColors.darkBorderDefault
                                        : LinearColors.lightBorderDefault,
                                  ),
                                ),
                                child: Text(
                                  '⌘K',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                ' for commands',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: widget.isDark
                                      ? LinearColors.darkTextTertiary
                                      : LinearColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'UTF-8',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_viewMode == ViewMode.reader) {
      return LinearMarkdownView(
        data: _activeDoc.content,
        isDark: widget.isDark,
        fontSize: _fontScale.baseSize,
        widthMode: _widthMode,
        scrollController: _scrollController,
        headingRegistry: _headingRegistry,
      );
    } else if (_viewMode == ViewMode.split) {
      return Row(
        children: [
          // Left Editor Pane
          Expanded(
            child: Container(
              color: widget.isDark
                  ? LinearColors.darkBgCode
                  : LinearColors.lightBgCode,
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _splitEditController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13.5,
                  height: 1.6,
                  color: widget.isDark
                      ? LinearColors.darkTextPrimary
                      : LinearColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            color: widget.isDark
                ? LinearColors.darkBorderSubtle
                : LinearColors.lightBorderSubtle,
          ),
          // Right Live Preview Pane
          Expanded(
            child: LinearMarkdownView(
              data: _activeDoc.content,
              isDark: widget.isDark,
              fontSize: _fontScale.baseSize,
              widthMode: ContentWidthMode.wide,
              scrollController: _scrollController,
              headingRegistry: _headingRegistry,
            ),
          ),
        ],
      );
    } else {
      // Source View
      return Container(
        color: widget.isDark ? LinearColors.darkBgCode : LinearColors.lightBgCode,
        padding: const EdgeInsets.all(32),
        child: TextField(
          controller: _splitEditController,
          maxLines: null,
          expands: true,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14.5,
            height: 1.6,
            color: widget.isDark
                ? LinearColors.darkTextPrimary
                : LinearColors.lightTextPrimary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
        ),
      );
    }
  }

  // Sidebar Implementation
  Widget _buildSidebar() {
    final bgSidebar = widget.isDark
        ? LinearColors.darkBgSidebar
        : LinearColors.lightBgSidebar;
    final borderSubtle = widget.isDark
        ? LinearColors.darkBorderSubtle
        : LinearColors.lightBorderSubtle;
    final textSecondary = widget.isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;

    final filteredDocs = _sidebarFilter.isEmpty
        ? _documents
        : _documents.where((d) =>
            d.title.toLowerCase().contains(_sidebarFilter) ||
            d.folder.toLowerCase().contains(_sidebarFilter)).toList();

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: bgSidebar,
        border: Border(right: BorderSide(color: borderSubtle)),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [LinearColors.accent, LinearColors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'M',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MarkMyWord',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? LinearColors.darkTextPrimary
                            : LinearColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? LinearColors.darkBgSurface
                    : LinearColors.lightBgSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 15, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchFilterController,
                      style: GoogleFonts.inter(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Jump to file... ⌘P',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: widget.isDark
                              ? LinearColors.darkTextTertiary
                              : LinearColors.lightTextTertiary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned & Recent Documents List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'DOCUMENTS',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: widget.isDark
                          ? LinearColors.darkTextTertiary
                          : LinearColors.lightTextTertiary,
                    ),
                  ),
                ),
                for (final doc in filteredDocs)
                  InkWell(
                    onTap: () => _switchDocument(doc),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: doc.id == _activeDoc.id
                            ? (widget.isDark
                                ? LinearColors.darkSurfaceActive
                                : LinearColors.lightSurfaceActive)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            doc.isLarge
                                ? Icons.inventory_2_outlined
                                : (doc.tag == 'Specs'
                                    ? Icons.architecture
                                    : Icons.description_outlined),
                            size: 15,
                            color: doc.id == _activeDoc.id
                                ? LinearColors.accentHover
                                : textSecondary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              doc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: doc.id == _activeDoc.id
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: doc.id == _activeDoc.id
                                    ? (widget.isDark
                                        ? LinearColors.darkTextPrimary
                                        : LinearColors.lightTextPrimary)
                                    : textSecondary,
                              ),
                            ),
                          ),
                          if (doc.tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: doc.isLarge
                                    ? LinearColors.amber.withValues(alpha: 0.18)
                                    : LinearColors.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                doc.tag!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: doc.isLarge
                                      ? LinearColors.amber
                                      : LinearColors.accentHover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Sidebar Footer: Open File (⌘O)
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _openLocalFile,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? LinearColors.darkBgSurface
                      : LinearColors.lightBgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open,
                        size: 14, color: LinearColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Open File (⌘O)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? LinearColors.darkTextPrimary
                            : LinearColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Table of Contents Sidebar
  Widget _buildTocSidebar() {
    final bgApp = widget.isDark ? LinearColors.darkBgApp : LinearColors.lightBgApp;
    final borderSubtle = widget.isDark
        ? LinearColors.darkBorderSubtle
        : LinearColors.lightBorderSubtle;
    final textTertiary = widget.isDark
        ? LinearColors.darkTextTertiary
        : LinearColors.lightTextTertiary;
    final headings = _extractHeadings();

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: bgApp,
        border: Border(left: BorderSide(color: borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.format_list_bulleted,
                      size: 13,
                      color: LinearColors.accent,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'OUTLINE',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
                if (headings.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? LinearColors.darkBgSurfaceElevated
                          : LinearColors.lightBgSurfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Text(
                      '${headings.length}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: headings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_list_bulleted,
                          size: 24,
                          color: textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No sections found',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add # headings to outline',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: textTertiary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: headings.length,
                    itemBuilder: (context, index) {
                      final item = headings[index];
                      final isActive = _activeHeadingId == item.id ||
                          (_activeHeadingId == null && index == 0);
                      return _TocItemRow(
                        item: item,
                        isActive: isActive,
                        isDark: widget.isDark,
                        onTap: () => _scrollToHeading(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: active
                ? (widget.isDark
                    ? LinearColors.darkSurfaceActive
                    : LinearColors.lightSurfaceActive)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active
                ? LinearColors.accentHover
                : (widget.isDark
                    ? LinearColors.darkTextSecondary
                    : LinearColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTab(
      String label, IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      key: ValueKey('tab_$label'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? (widget.isDark
                  ? LinearColors.darkBgSurface
                  : LinearColors.lightBgSurface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? LinearColors.accent
                  : (widget.isDark
                      ? LinearColors.darkTextSecondary
                      : LinearColors.lightTextSecondary),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active
                    ? (widget.isDark
                        ? LinearColors.darkTextPrimary
                        : LinearColors.lightTextPrimary)
                    : (widget.isDark
                        ? LinearColors.darkTextSecondary
                        : LinearColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TocItemRow extends StatefulWidget {
  final HeadingItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TocItemRow({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TocItemRow> createState() => _TocItemRowState();
}

class _TocItemRowState extends State<_TocItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isActive = widget.isActive;
    final isDark = widget.isDark;

    // Indentation based on level
    final double padLeft = ((item.level - 1) * 10.0).clamp(0.0, 40.0);

    final activeBg = isDark
        ? LinearColors.accent.withValues(alpha: 0.12)
        : LinearColors.accent.withValues(alpha: 0.09);
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.035);

    Color textColor;
    if (isActive) {
      textColor = LinearColors.accent;
    } else if (_isHovered) {
      textColor = isDark
          ? LinearColors.darkTextPrimary
          : LinearColors.lightTextPrimary;
    } else {
      if (item.level == 1) {
        textColor = isDark
            ? LinearColors.darkTextPrimary
            : LinearColors.lightTextPrimary;
      } else {
        textColor = isDark
            ? LinearColors.darkTextSecondary
            : LinearColors.lightTextSecondary;
      }
    }

    final fontWeight = item.level == 1
        ? FontWeight.w600
        : (isActive ? FontWeight.w500 : FontWeight.w400);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: item.text,
        waitDuration: const Duration(milliseconds: 700),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 2),
            padding: EdgeInsets.only(
              left: 6 + padLeft,
              right: 8,
              top: 5,
              bottom: 5,
            ),
            decoration: BoxDecoration(
              color: isActive ? activeBg : (_isHovered ? hoverBg : Colors.transparent),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                // Active indicator line or subtle bullet
                if (isActive)
                  Container(
                    width: 2.5,
                    height: 12,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: LinearColors.accent,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  )
                else if (item.level > 1)
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? LinearColors.darkTextTertiary
                              : LinearColors.lightTextTertiary)
                          .withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    item.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: item.level == 1 ? 12.0 : 11.5,
                      fontWeight: fontWeight,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

