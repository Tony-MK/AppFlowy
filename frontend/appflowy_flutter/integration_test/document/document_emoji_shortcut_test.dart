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
      doTest(tester, insertingEmoji);
    });

    testWidgets('insert emoji with arrow keys', (tester) async {
      doTest(tester, insertingEmojiWithArrowKeys);
    });
  });
}

void doTest(WidgetTester tester, Function func) async {
  await tester.initializeAppFlowy();
  await tester.tapGoButton();
  await createDocumentAndOpenMenu(tester);
  await func(tester);
  checkEmoji(tester);
  await tester.wait(5000);
}

// search the emoji list with keyword 'grinning' and insert emoji
Future<void> insertingEmoji(
  WidgetTester tester,
) async {
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
}

// search the emoji list with keyword 's'
// press the key combination [right, down, left, up]
// insert the emoji
Future<void> insertingEmojiWithArrowKeys(
  WidgetTester tester,
) async {
  // type 's'
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyS);
  await tester.wait(500);

  // perform arrow key movements
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowLeft);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowUp);
}

void checkEmoji(WidgetTester tester) async {
  await tester.wait(80);

  // insert emoji
  await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

  final editorState = tester.editor.getCurrentEditorState();
  final text = editorState.document.last!.delta!.toPlainText();
  expect(text, "😃");
}

Future<void> createDocumentAndOpenMenu(WidgetTester tester) async {
  await tester.createNewPageWithName(
    name: 'document_${uuid()}',
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
