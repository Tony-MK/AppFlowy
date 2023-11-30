import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('emoji shortcut in document', () {
    testWidgets('insert emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      //await insertingEmoji(tester);
    });

    testWidgets('insert emoji with arrow keys', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      await insertingEmojiWithArrowKeys(tester);
    });
  });
}

// search the emoji list with keyword 'grinning' and insert emoji
Future<void> insertingEmoji(
  WidgetTester tester,
) async {
  await createDocumentAndOpenMenu(tester);

  // type 'grinning'
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyG);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyR);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyI);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyN);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyN);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyI);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyN);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyG);
  await tester.wait(500);

  // insert emoji
  await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
  final editorState = tester.editor.getCurrentEditorState();
  final text = editorState.document.last!.delta!.toPlainText();
  expect(text, "😃");
}

// search the emoji list with keyword 's'
// press the key combination [right, down, left, up]
// insert the emoji
Future<void> insertingEmojiWithArrowKeys(
  WidgetTester tester,
) async {
  await createDocumentAndOpenMenu(tester);

  // type 's'
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyS);
  await tester.wait(500);

  // perform arrow key movements
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowLeft);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowUp);

  // insert emoji
  await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
  await tester.wait(80);

  final editorState = tester.editor.getCurrentEditorState();
  final text = editorState.document.last!.delta!.toPlainText();
  expect(text, "😃");
}

Future<void> createDocumentAndOpenMenu(WidgetTester tester) async {
  final name = 'document_${uuid()}';

  await tester.createNewPageWithName(
    name: name,
    layout: ViewLayoutPB.Document,
    openAfterCreated: false,
  );

  // This is a workaround since the openAfterCreated
  //  option does not work in createNewPageWithName method
  await tester.tap(find.byType(SingleInnerViewItem).first);
  await tester.pumpAndSettle();

  await tester.editor.tapLineOfEditorAt(0);
  await tester.pumpAndSettle();

  // open ':' menu
  await tester.ime.insertCharacter(":");
  await tester.pumpAndSettle();
}
