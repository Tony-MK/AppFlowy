import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const double menuWidth = 300.0;
const double menuHeight = 200.0;
const Offset menuOffset = Offset(0, 8.0);

const EmojiPickerConfig config = EmojiPickerConfig(
  emojiNumberPerRow: emojiNumberPerRow,
  emojiSizeMax: emojiSizeMax,
  bgColor: Colors.transparent,
  categoryIconColor: Colors.grey,
  selectedCategoryIconColor: Color(0xff333333),
  progressIndicatorColor: Color(0xff333333),
  buttonMode: ButtonMode.CUPERTINO,
  initCategory: EmojiCategory.RECENT,
);

CharacterShortcutEvent emojiShortcutCommand(
  BuildContext context, {
  String character = ':',
  bool shouldInsertKeyword = true,
}) {
  return CharacterShortcutEvent(
    key: 'show emoji selection menu',
    character: character,
    handler: (editorState) async {
      opensEmojiShortcutPicker(
        editorState,
        context,
      );
      return true;
    },
  );
}

void opensEmojiShortcutPicker(
  EditorState editorState,
  BuildContext context,
) async {
  final selectionRects = editorState.service.selectionService.selectionRects;
  if (selectionRects.isEmpty) return;

  final editorHeight = editorState.renderBox!.size.height;
  final editorWidth = editorState.renderBox!.size.width;
  final editorOffset =
      editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

  // Cursor postion
  final cursor = selectionRects.first;

  // Check if emoji menu is will overflow on right side of editor
  final bool dxOverflow =
      cursor.bottomLeft.dx + menuWidth > editorWidth + editorOffset.dx;

  // By default, display the menu under the cursor
  var dy = cursor.bottomLeft.dy + menuOffset.dy;

  // Determine if there is enough space under the cursor to display the menu
  if (menuHeight + dy >= editorHeight + editorOffset.dy) {
    // If not, display the menu above the cursor
    dy = cursor.topLeft.dy - menuOffset.dy - menuHeight;
  }

  keepEditorFocusNotifier.increase();

  late OverlayEntry emojiShortcutPickerMenuEntry;
  emojiShortcutPickerMenuEntry = FullScreenOverlayEntry(
    top: dy,
    right: dxOverflow ? 0 : null,
    left: dxOverflow ? null : cursor.bottomLeft.dx,
    dismissCallback: () => keepEditorFocusNotifier.decrease(),
    builder: (context) => Material(
      child: Container(
        width: menuWidth,
        height: menuHeight,
        padding: const EdgeInsets.all(4.0),
        child: EmojiPicker(
          config: config,
          customWidget: (config, state) {
            return EmojiShortcutPickerView(
              config,
              state,
              editorState,
              emojiShortcutPickerMenuEntry.remove,
            );
          },
          onEmojiSelected: (category, emoji) {
            editorState.insertTextAtCurrentSelection(emoji.emoji);
          },
        ),
      ),
    ),
  ).build();
  Overlay.of(context).insert(emojiShortcutPickerMenuEntry);
}
