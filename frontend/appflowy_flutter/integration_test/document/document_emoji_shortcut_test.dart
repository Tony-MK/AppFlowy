import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
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

const String expected = "😼";
const String emoji = 'smile';
const List<LogicalKeyboardKey> emojiKeys = [
  LogicalKeyboardKey.keyS, // Smile
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyE,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('emoji shortcut in document', () {
    testWidgets('insert emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.pumpAndSettle();

      await tester.tapGoButton();
      await tester.pumpAndSettle();

      tester.expectToSeeHomePage();

      await tester.createNewPageWithName(
        //name: 'document',
        layout: ViewLayoutPB.Document,
        openAfterCreated: true,
      );

      await tester.pumpAndSettle();

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      // Press ':' to open the menu
      await tester.ime.insertText(':');
      await tester.pumpAndSettle();

      expect(find.byType(EmojiShortcutPickerView), findsOneWidget);

      // Search for the emoji most similar to the text
      // Generate keyboard press events
      await FlowyTestKeyboard.simulateKeyDownEvent(tester: tester, emojiKeys);
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
    });

    testWidgets('insert gringing emoji with arrow keys', (tester) async {
      insertEmoji(tester, ':gringing', "😃");
    });
  });
}

void insertEmoji(
  WidgetTester tester,
  String emoji,
  String expected, {
  List<LogicalKeyboardKey> keys = arrowKeys,
}) async {}
