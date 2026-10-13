import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mark_my_words/main.dart';
import 'package:mark_my_words/widgets/command_palette.dart';
import 'package:mark_my_words/widgets/markdown_view.dart';
import 'package:mark_my_words/widgets/mermaid_widget.dart';

void main() {
  testWidgets('MarkMyWord app launches cleanly and renders desktop UI',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MarkMyWordsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // App bar title / window indicator
    expect(find.text('MarkMyWord'), findsOneWidget);

    // Segmented Switcher buttons
    expect(find.text('Reader'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Source'), findsWidgets);

    // Sidebar items
    expect(find.text('Linear 2026 Product Spec.md'), findsWidgets);

    // Status bar
    expect(find.text('GFM Spec 0.31'), findsOneWidget);
    expect(find.text('⌘K'), findsWidgets);
  });

  testWidgets('Switch between Reader, Split, and Source view modes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MarkMyWordsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Initially in Reader mode: only sidebar search TextField is present
    expect(find.byType(TextField), findsOneWidget);

    // Switch to Source mode: 2 TextFields (sidebar search + markdown source editor)
    await tester.tap(find.byKey(const ValueKey('tab_Source')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TextField), findsNWidgets(2));

    // Switch to Split mode: 2 TextFields
    await tester.tap(find.byKey(const ValueKey('tab_Split')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TextField), findsNWidgets(2));

    // Switch back to Reader mode: only sidebar search TextField remains
    await tester.tap(find.byKey(const ValueKey('tab_Reader')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Command Palette can be opened and dismissed',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MarkMyWordsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on the ⌘K badge in titlebar
    final kbdFinder = find.widgetWithText(InkWell, '⌘K').first;
    await tester.tap(kbdFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Command palette dialog is shown
    expect(find.byType(CommandPaletteDialog), findsOneWidget);
    expect(find.text('Type a command or search documents...'), findsOneWidget);

    // Dismiss dialog using Escape key
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CommandPaletteDialog), findsNothing);
  });

  testWidgets('Mermaid widget renders in diagram and source mode',
      (WidgetTester tester) async {
    const sampleMermaid = '''
flowchart LR
    A["Disk (.md file)"] --> B["Memory Stream"]
    B --> C["Fast AST Tokenizer"]
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MermaidWidget(
            code: sampleMermaid,
            isDark: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('MERMAID DIAGRAM'), findsOneWidget);
    expect(find.text('Diagram'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);

    // Toggle to Source
    await tester.tap(find.text('Source'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(sampleMermaid.trim()), findsOneWidget);
  });

  testWidgets('Clicking outline section scrolls to section and marks it active',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MarkMyWordsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify OUTLINE header is visible
    expect(find.text('OUTLINE'), findsOneWidget);

    // Find the main markdown scrollable inside LinearMarkdownView
    final markdownScrollableFinder = find.descendant(
      of: find.byType(LinearMarkdownView),
      matching: find.byType(Scrollable),
    );
    final mainScrollable = tester.state<ScrollableState>(markdownScrollableFinder.first);
    expect(mainScrollable.position.pixels, 0.0);

    // Find outline item for a subsequent section in Linear 2026 Product Spec.md
    final outlineItem = find.text('2. Core Architecture & Requirements');
    expect(outlineItem, findsWidgets);

    // Tap the outline item in the right sidebar
    await tester.tap(outlineItem.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify view has smoothly scrolled down to the section
    expect(mainScrollable.position.pixels, greaterThan(100.0));
  });
}

