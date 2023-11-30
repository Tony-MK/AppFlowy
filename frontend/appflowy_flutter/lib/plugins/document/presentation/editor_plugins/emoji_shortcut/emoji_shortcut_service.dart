import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

const menuHeight = 200.0;
const menuWidth = 300.0;
const menuOffset = Offset(0, 8);

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

class EmojiShortcutService {
  late OverlayEntry emojiPickerMenuEntry;

  customEmojiMenuLink(
    BuildContext context, {
    bool shouldInsertKeyword = true,
    String character = ':',
  }) {
    return CharacterShortcutEvent(
      key: 'show emoji selection menu',
      character: character,
      handler: (editorState) async {
        showEmojiPickerMenu(
          editorState,
          context,
          shouldInsertKeyword,
        );
        return true;
      },
    );
  }

  void showEmojiPickerMenu(
    EditorState editorState,
    BuildContext context,
    bool shouldInsertCharacter,
  ) async {
    final container = Overlay.of(context);
    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    } else if (shouldInsertCharacter) {
      // Have no idea why the focus will lose after inserting on web.
      if (foundation.kIsWeb) {
        keepEditorFocusNotifier.increase();
      }
      await editorState.insertTextAtPosition(
        ':',
        position: editorState.selection!.start,
      );
      if (foundation.kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => keepEditorFocusNotifier.decrease(),
        );
      }
    }

    keepEditorFocusNotifier.increase();

    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    // Cursor location
    final cursor = selectionRects.first;

    // By default, display the menu under the cursor
    var dy = cursor.bottomLeft.dy + menuOffset.dy + menuHeight;

    // Determine if there is enough space under the cursor to display the menu
    if (dy >= editorHeight + editorOffset.dy) {
      // If not, display the menu above the cursor
      dy = cursor.topLeft.dy - menuOffset.dy - menuHeight;
    }

    // Check if emoji menu is will overflow on right side of editor
    final bool dxOverflow =
        cursor.bottomLeft.dx + menuWidth >= editorWidth + editorOffset.dx;

    emojiPickerMenuEntry = FullScreenOverlayEntry(
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
              return EmojiShortcutPickerView(config, state, editorState, () {
                emojiPickerMenuEntry.remove;
              });
            },
            onEmojiSelected: (category, emoji) {
              editorState.insertTextAtCurrentSelection(emoji.emoji);
            },
          ),
        ),
      ),
    ).build();
    container.insert(emojiPickerMenuEntry);
  }
}
