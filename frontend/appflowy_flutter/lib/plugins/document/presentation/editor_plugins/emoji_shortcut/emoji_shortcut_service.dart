import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

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
        final container = Overlay.of(context);
        showEmojiPickerMenu(
          container,
          editorState,
          context,
          shouldInsertKeyword,
        );
        return true;
      },
    );
  }

  void showEmojiPickerMenu(
    OverlayState container,
    EditorState editorState,
    BuildContext context,
    bool shouldInsertCharacter,
  ) async {
    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    if (shouldInsertCharacter) {
      if (foundation.kIsWeb) {
        // Have no idea why the focus will lose after inserting on web.
        keepEditorFocusNotifier.value += 1;
        await editorState.insertTextAtPosition(
          ':',
          position: editorState.selection!.start,
        );
        WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) => keepEditorFocusNotifier.value -= 1,
        );
      } else {
        await editorState.insertTextAtPosition(
          ':',
          position: editorState.selection!.start,
        );
      }
    }
    // Workaround: We can customize the padding through the [EditorStyle],
    //  but the coordinates of overlay are not properly converted currently.
    //  Just subtract the padding here as a result.
    const menuHeight = 200.0;
    const menuWidth = 300.0;
    const menuOffset = Offset(0, 8);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;

    // Cursor
    final cursor = selectionRects.first;

    // By default display it under the cursor
    var offset = cursor.bottomLeft + menuOffset;

    // But if there is no space at bottom of the editor
    if (offset.dy + menuHeight >= editorHeight + editorOffset.dy) {
      // Display it above the cursor
      offset = cursor.topLeft - menuOffset;
      offset = Offset(offset.dx, offset.dy - menuHeight);
    }

    final bool xAxisOverflow =
        offset.dx + menuWidth >= editorWidth + editorOffset.dx;

    keepEditorFocusNotifier.increase();

    emojiPickerMenuEntry = FullScreenOverlayEntry(
      left: xAxisOverflow ? null : offset.dx,
      right: xAxisOverflow ? 0 : null,
      top: offset.dy,
      dismissCallback: () => keepEditorFocusNotifier.decrease(),
      builder: (context) => Material(
        child: Container(
          width: menuWidth,
          height: menuHeight,
          padding: const EdgeInsets.all(4.0),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              editorState.insertTextAtCurrentSelection(emoji.emoji);
            },
            config: config,
            customWidget: (config, state) {
              return ShortcutEmojiPickerView(config, state, editorState, () {
                emojiPickerMenuEntry.remove();
              });
            },
          ),
        ),
      ),
    ).build();
    container.insert(emojiPickerMenuEntry);
  }
}
