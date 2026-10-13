import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mark_my_words/services/system_service.dart';
import 'package:mark_my_words/widgets/install_dialogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.markMyWords/system');
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methodCalls.add(call);
      switch (call.method) {
        case 'isRunningFromApplications':
          return false;
        case 'moveToApplicationsFolder':
          return true;
        case 'isDefaultMarkdownViewer':
          return false;
        case 'setDefaultMarkdownViewer':
          return true;
        case 'openApplicationsFolder':
          return null;
        case 'getInitialOpenedFile':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('MoveToApplicationsDialog displays drag instructions and actions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoveToApplicationsDialog(isDark: true),
        ),
      ),
    );
    await tester.pump();

    // Verify dialog header
    expect(find.text('Install MarkMyWord to Applications'), findsOneWidget);
    expect(find.text('macOS Installation & System Setup'), findsOneWidget);

    // Verify visual drag-to-applications illustration
    expect(find.text('MarkMyWord.app'), findsOneWidget);
    expect(find.text('Drag to install'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);

    // Verify buttons
    expect(find.text('Open Finder'), findsOneWidget);
    expect(find.text("Don't Move"), findsOneWidget);
    expect(find.text('Move to Applications'), findsOneWidget);

    // Tap "Open Finder"
    await tester.tap(find.text('Open Finder'));
    await tester.pump();
    expect(methodCalls.any((call) => call.method == 'openApplicationsFolder'),
        isTrue);

    // Tap "Move to Applications"
    await tester.tap(find.text('Move to Applications'));
    await tester.pump();
    expect(methodCalls.any((call) => call.method == 'moveToApplicationsFolder'),
        isTrue);
  });

  testWidgets(
      'Dragging MarkMyWord into Applications triggers moveToApplicationsFolder',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoveToApplicationsDialog(isDark: true),
        ),
      ),
    );
    await tester.pump();

    final sourceFinder = find.text('MarkMyWord.app');
    final targetFinder = find.text('Applications');

    final gesture = await tester.startGesture(tester.getCenter(sourceFinder));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(targetFinder));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(methodCalls.any((call) => call.method == 'moveToApplicationsFolder'),
        isTrue);
  });

  testWidgets('DefaultViewerDialog displays file association prompt and buttons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DefaultViewerDialog(isDark: true),
        ),
      ),
    );
    await tester.pump();

    // Verify dialog content
    expect(find.text('Set as Default Markdown Reader'), findsOneWidget);
    expect(find.text('.md'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Set as Default'), findsOneWidget);

    // Tap "Set as Default"
    await tester.tap(find.text('Set as Default'));
    await tester.pump();
    expect(methodCalls.any((call) => call.method == 'setDefaultMarkdownViewer'),
        isTrue);

    // Let the auto-dismiss timer complete
    await tester.pump(const Duration(milliseconds: 1500));
  });

  test('SystemService correctly invokes method channel', () async {
    expect(await SystemService.isRunningFromApplications(), isFalse);
    expect(await SystemService.isDefaultMarkdownViewer(), isFalse);
    expect(await SystemService.moveToApplicationsFolder(), isTrue);
    expect(await SystemService.setDefaultMarkdownViewer(), isTrue);
    await SystemService.openApplicationsFolder();
    expect(methodCalls.any((c) => c.method == 'openApplicationsFolder'), isTrue);
  });
}
