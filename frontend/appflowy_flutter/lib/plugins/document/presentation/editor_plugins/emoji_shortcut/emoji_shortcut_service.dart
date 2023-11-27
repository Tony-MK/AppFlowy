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
  EmojiShortcutService({
    required this.context,
    required this.editorState,
  });

  final BuildContext context;
  final EditorState editorState;
  Offset _offset = Offset.zero;
  Alignment _alignment = Alignment.topLeft;
  CharacterShortcutEvent emojiShortcutCommand(
    BuildContext context, {
    String character = ':',
  }) {
    return CharacterShortcutEvent(
      key: 'show emoji selection menu',
      character: character,
      handler: (editorState) async {
        show(Overlay.of(context));
        return true;
      },
    );
  }

  void show(OverlayState container) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _show(container);
    });
  }

  Future<void> _show(OverlayState container) async {
    //dismiss();

    if (foundation.kIsWeb) {
      // Have no idea why the focus will lose after inserting on web.
      keepEditorFocusNotifier.value += 1;
      await editorState.insertTextAtPosition(
        ':',
        position: editorState.selection!.start,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => keepEditorFocusNotifier.decrease(),
      );
    } else {
      await editorState.insertTextAtPosition(
        ':',
        position: editorState.selection!.start,
      );
    }
    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    calculateSelectionMenuOffset(selectionRects.first);
    final (left, top, right, bottom) = getPosition();

    keepEditorFocusNotifier.increase();
    late OverlayEntry emojiPickerMenuEntry;
    emojiPickerMenuEntry = FullScreenOverlayEntry(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      dismissCallback: keepEditorFocusNotifier.decrease,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Container(
          width: 300,
          height: 250,
          padding: const EdgeInsets.all(4.0),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              editorState.insertTextAtCurrentSelection(emoji.emoji);
            },
            config: config,
            customWidget: (config, state) {
              return EmojiPickerShortcutView(
                config,
                state,
                editorState,
                emojiPickerMenuEntry.remove,
              );
            },
          ),
        ),
      ),
    ).build();
    container.insert(emojiPickerMenuEntry);
  }

  Alignment get alignment {
    return _alignment;
  }

  Offset get offset {
    return _offset;
  }

  (double? left, double? top, double? right, double? bottom) getPosition() {
    double? left, top, right, bottom;
    switch (alignment) {
      case Alignment.topLeft:
        left = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomLeft:
        left = offset.dx;
        bottom = offset.dy;
        break;
      case Alignment.topRight:
        right = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomRight:
        right = offset.dx;
        bottom = offset.dy;
        break;
    }

    return (left, top, right, bottom);
  }

  void calculateSelectionMenuOffset(Rect rect) {
    // Workaround: We can customize the padding through the [EditorStyle],
    // but the coordinates of overlay are not properly converted currently.
    // Just subtract the padding here as a result.
    const menuHeight = 200.0;
    const menuOffset = Offset(0, 10);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;

    // show below default
    _alignment = Alignment.topLeft;
    final bottomRight = rect.bottomRight;
    final topRight = rect.topRight;
    var offset = bottomRight + menuOffset;
    _offset = Offset(
      offset.dx,
      offset.dy,
    );

    // show above
    if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      offset = topRight - menuOffset;
      _alignment = Alignment.bottomLeft;

      _offset = Offset(
        offset.dx,
        MediaQuery.of(context).size.height - offset.dy,
      );
    }

    // show on left
    if (_offset.dx - editorOffset.dx > editorWidth / 2) {
      _alignment = _alignment == Alignment.topLeft
          ? Alignment.topRight
          : Alignment.bottomRight;

      _offset = Offset(
        editorWidth - _offset.dx + editorOffset.dx,
        _offset.dy,
      );
    }
  }
}
