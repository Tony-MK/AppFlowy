import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/keyboard.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const emoji = '😁';

  group('emoji shortcut in document', () {
    testWidgets('Update page icon in sidebar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create document, board, grid and calendar views
      for (final value in ViewLayoutPB.values) {
        await tester.createNewPageWithName(
          name: value.name,
          parentName: gettingStarted,
          layout: value,
        );

        // update its icon
        await tester.updatePageIconInSidebarByName(
          name: value.name,
          parentName: gettingStarted,
          layout: value,
          icon: emoji,
        );

        tester.expectViewHasIcon(
          value.name,
          value,
          emoji,
        );
      }
    });

    testWidgets('insert gringing emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(
        name: 'gringing',
        layout: ViewLayoutPB.Document,
      );

      /*
      await tester.tap(find.byType(SingleInnerViewItem).first);
      await tester.pumpAndSettle();

      // This is a workaround since the openAfterCreated
      // option does not work in createNewPageWithName method
      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();
      */

      // Search the emoji list with keyword
      await tester.ime.insertText(":gringing");
      await tester.pumpAndSettle();

      await FlowyTestKeyboard.simulateKeyDownEvent(
        tester: tester,
        // Insert the emoji
        [LogicalKeyboardKey.enter],
      );

      final editorState = tester.editor.getCurrentEditorState();
      expect(
        editorState.document.last!.delta!.toPlainText(),
        "😃",
      );
    });

    testWidgets('insert gringing emoji with arrow keys', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      insertEmoji(tester, ':gringing', "😃", true);
    });

    testWidgets('insert angry emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      insertEmoji(tester, ':angry', "😃", false);
    });

    testWidgets('insert angry emoji with arrow keys', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      insertEmoji(tester, ':angry', "😃", true);
    });
  });
}

void insertEmoji(
  WidgetTester tester,
  String emojiKeyword,
  String expected,
  useArrowKeys,
) async {
  await tester.createNewPageWithName(
    name: 'document_${uuid()}',
    layout: ViewLayoutPB.Document,
  );

  await tester.pumpAndSettle();

  await tester.tap(find.byType(SingleInnerViewItem).first);
  await tester.pumpAndSettle();

  // This is a workaround since the openAfterCreated
  // option does not work in createNewPageWithName method
  await tester.editor.tapLineOfEditorAt(0);
  await tester.pumpAndSettle();

  // Search the emoji list with keyword
  await tester.ime.insertText(emojiKeyword);
  await tester.pumpAndSettle();

  await FlowyTestKeyboard.simulateKeyDownEvent(
    tester: tester,
    useArrowKeys
        ? [
            // Perform arrow key combination [right, down, left, up]
            LogicalKeyboardKey.arrowRight,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowUp,

            // Insert the emoji
            LogicalKeyboardKey.enter,
          ]
        : [LogicalKeyboardKey.enter], // Insert the emoji
  );

  final editorState = tester.editor.getCurrentEditorState();
  expect(
    editorState.document.last!.delta!.toPlainText(),
    expected,
  );
}
