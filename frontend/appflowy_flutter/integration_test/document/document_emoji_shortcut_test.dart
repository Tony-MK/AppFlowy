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

  group('emoji shortcut in document', () {
    testWidgets('insert gringing emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      insertEmoji(tester, ':gringing', "😃", false);
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
    openAfterCreated: true,
  );

  await tester.tap(find.byType(SingleInnerViewItem).first);
  await tester.pumpAndSettle();

  // This is a workaround since the openAfterCreated
  // option does not work in createNewPageWithName method
  await tester.editor.tapLineOfEditorAt(0);
  await tester.pumpAndSettle();

  // Search the emoji list with keyword
  tester.ime.insertText(emojiKeyword);
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
  await tester.pumpAndSettle();

  final editorState = tester.editor.getCurrentEditorState();
  expect(
    editorState.document.last!.delta!.toPlainText(),
    expected,
  );
}
