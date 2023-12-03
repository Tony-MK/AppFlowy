import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('emoji shortcut in document', () {
    testWidgets('insert gringing emoji', (tester) async {
      const int waitDuration = 5000;
      const String expected = "😃";
      const String emoji = 'smile';
      const List<LogicalKeyboardKey> emojiKeys = [
        LogicalKeyboardKey.keyS, // Smile
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyE,
      ];

      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      tester.expectToSeeHomePage();

      // Create a new page
      await tester.createNewPageWithName(
        name: '$emoji${arrowKeys.isEmpty ? "" : " via Keys"}',
        layout: ViewLayoutPB.Document,
        openAfterCreated: true,
      );

      await tester.wait(waitDuration);

      // This is a workaround since the openAfterCreated
      // option does not work in createNewPageWithName method
      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await tester.wait(waitDuration);

      // Press ':' to open the menu
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.semicolon, // Mac US keyboard format input for ":":
        isShiftPressed: true, // depends on computer
      );

      await tester.wait(waitDuration);

      // Check if text is emoji
      expect(
        tester.editor
            .getCurrentEditorState()
            .document
            .last!
            .delta!
            .toPlainText(),
        ':',
      );

      // Search for the emoji most similar to the text
      // Generate keyboard press events
      await FlowyTestKeyboard.simulateKeyDownEvent(tester: tester, emojiKeys);
      await tester.wait(waitDuration);

      // Check if text is emoji
      expect(
        tester.editor
            .getCurrentEditorState()
            .document
            .last!
            .delta!
            .toPlainText(),
        ':$emoji',
      );

      await tester.wait(80000);

      expect(find.byType(EmojiShortcutPickerViewState), findsOneWidget);

      // Generate keyboard press events
      // await FlowyTestKeyboard.simulateKeyDownEvent(
      //   tester: tester,
      //   [
      //     // Perform arrow keyboard combination eg: [RIGHT, DOWN, LEFT, UP]
      //     //...arrowKeys,
      //   ],
      // );

      // Press ENTER to insert the emoji and replace text
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

      // Check if text is replaced by emoji
      expect(
        tester.editor
            .getCurrentEditorState()
            .document
            .last!
            .delta!
            .toPlainText(),
        expected,
      );

      await FlowyTestKeyboard.simulateKeyDownEvent(tester: tester, emojiKeys);
      await tester.wait(waitDuration);

      // Check if text is emoji
      expect(
        tester.editor
            .getCurrentEditorState()
            .document
            .last!
            .delta!
            .toPlainText(),
        expected,
      );
    });

    testWidgets('insert gringing emoji with arrow keys', (tester) async {
      insertEmoji(tester, ':gringing', "😃");
    });

    testWidgets('insert angry emoji', (tester) async {
      insertEmoji(tester, ':angry', "😃", keys: []);
    });

    testWidgets('insert angry emoji with arrow keys', (tester) async {
      insertEmoji(tester, ':angry', "😃");
    });
  });
}

void insertEmoji(
  WidgetTester tester,
  String emoji,
  String expected, {
  List<LogicalKeyboardKey> keys = arrowKeys,
}) async {
  const int waitDuration = 8000;

  await tester.initializeAppFlowy();

  await tester.wait(waitDuration);

  await tester.tapGoButton();
  //tester.expectToSeeHomePage();

  await tester.wait(waitDuration);

  // Create a new page
  await tester.createNewPageWithName(
    name: '${emoji.substring(1)}${arrowKeys.isEmpty ? "" : " via Keys"}',
    layout: ViewLayoutPB.Document,
    openAfterCreated: true,
  );

  await tester.wait(waitDuration);

  // This is a workaround since the openAfterCreated
  // option does not work in createNewPageWithName method
  await tester.editor.tapLineOfEditorAt(0);
  await tester.pumpAndSettle();

  await tester.wait(waitDuration);

  // Perform command and search for the emoji closet to the text
  await tester.ime.insertText(emoji);
  await tester.pumpAndSettle();

  await tester.wait(waitDuration);

  // Check if text is emoji
  final editorState = tester.editor.getCurrentEditorState();
  expect(
    editorState.document.toString(),
    emoji,
  );

  // Generate keyboard press events
  await FlowyTestKeyboard.simulateKeyDownEvent(
    tester: tester,
    [
      // Perform arrow keyboard combination eg: [RIGHT, DOWN, LEFT, UP]
      ...arrowKeys,

      // Press ENTER to tnsert the emoji
      LogicalKeyboardKey.enter,
    ],
  );

  // Check if text is emoji
  expect(
    editorState.document.last!.delta!.toPlainText(),
    expected,
  );
}
