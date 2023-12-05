import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/keyboard.dart';
import '../util/util.dart';

const arrowKeys = [
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowUp,
];

const scaredKeys = [
  LogicalKeyboardKey.keyS, // Scared
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyD
];

const smirkKeys = [
  LogicalKeyboardKey.keyS, // Smirk
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyK,
];

const smileKeys = [
  LogicalKeyboardKey.keyS, // Smile
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyE,
];

const impKeys = [
  LogicalKeyboardKey.keyI, // Imp
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyP,
];

const robotKeys = [
  LogicalKeyboardKey.keyR, // Robot
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyT,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Insert Emoji', () {
    testWidgets('smiling face with halo', (tester) async {
      await insertEmoji(tester, 'smiling face with halo', '😏', smirkKeys, []);
    });

    testWidgets('smirk face', (tester) async {
      await insertEmoji(tester, 'smirk face', '😏', smirkKeys, []);
    });

    testWidgets('scared face', (tester) async {
      await insertEmoji(tester, 'scared face', '🙀', scaredKeys, []);
    });

    testWidgets('imp', (tester) async {
      await insertEmoji(tester, 'Imp', '👿', impKeys, []);
    });

    testWidgets('robot emoji', (tester) async {
      await insertEmoji(tester, 'robot', '🤖', robotKeys, []);
    });
  });

  group('Insert Emoji using arrow keys', () {
    testWidgets('smiling face with halo', (tester) async {
      await insertEmoji(tester, 'Smiling Face with Halo', '😏',
          smirkKeys.slice(0, smirkKeys.length - 2), arrowKeys);
    });

    testWidgets('smirk face', (tester) async {
      await insertEmoji(tester, 'smirk face', '😏',
          smirkKeys.slice(0, smirkKeys.length - 2), arrowKeys);
    });

    testWidgets('scared face', (tester) async {
      await insertEmoji(tester, 'scared Face', '🙀',
          scaredKeys.slice(0, scaredKeys.length - 2), arrowKeys);
    });

    testWidgets('imp', (tester) async {
      await insertEmoji(tester, 'Imp', '👿',
          impKeys.slice(0, robotKeys.length - 2), arrowKeys);
    });

    testWidgets('robot', (tester) async {
      await insertEmoji(tester, 'robot', '🤖',
          robotKeys.slice(0, robotKeys.length - 2), arrowKeys);
    });
  });
}

Future<void> insertEmoji(
  WidgetTester tester,
  String emoji,
  String expected,
  List<LogicalKeyboardKey> emojiKeys,
  List<LogicalKeyboardKey> arrowKeys,
) async {
  await tester.initializeAppFlowy();
  await tester.tapGoButton();
  tester.expectToSeeHomePage();

  await tester.createNewPageWithName(
    name: 'Test $emoji ${arrowKeys.isEmpty ? "" : " (keyboard) "}',
    layout: ViewLayoutPB.Document,
    openAfterCreated: true,
  );

  await tester.editor.tapLineOfEditorAt(0);

  // Determine whether the emoji picker hasn't been opened
  expect(find.byType(EmojiShortcutPickerView), findsNothing);

  // Press ':' to open the menu
  await tester.ime.insertText(':');

  // Determine whether the shortcut works and the emoji picker is opened
  expect(find.byType(EmojiShortcutPickerView), findsOneWidget);

  // Search for the emoji most similar to the text
  // Generate keyboard press events
  // await FlowyTestKeyboard.simulateKeyDownEvent(tester: tester, emojiKeys);

  await FlowyTestKeyboard.simulateKeyDownEvent(
    tester: tester,

    // Perform arrow keyboard combination eg: [RIGHT, DOWN, LEFT, UP]
    [...emojiKeys, ...arrowKeys, LogicalKeyboardKey.enter],
  );

  // Press ENTER to insert the emoji and replace text
  //await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

  // Determine whether the emoji picker is closed on enter
  expect(find.byType(EmojiShortcutPickerView), findsNothing);

  // Check if typed text is replaced by emoji
  expect(
    tester.editor.getCurrentEditorState().document.last!.delta!.toPlainText(),
    expected,
  );
}
