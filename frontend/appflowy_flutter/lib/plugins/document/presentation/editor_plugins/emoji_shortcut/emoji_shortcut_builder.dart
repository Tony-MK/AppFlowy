import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker_builder.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_view_state.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_category_models.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double emojiSizeMax = 28;
const int emojiNumberPerRow = 8;
const int resultsFilterCount = 8;

const Color selectedItemColor = Color(0xFFE0F8FF);

final Map<LogicalKeyboardKey, int> arrowKeys = {
  LogicalKeyboardKey.arrowRight: 1,
  LogicalKeyboardKey.arrowLeft: -1,
  LogicalKeyboardKey.arrowDown: emojiNumberPerRow,
  LogicalKeyboardKey.arrowUp: -emojiNumberPerRow,
};

class EmojiShortcutPickerView extends EmojiPickerBuilder {
  final EditorState editorState;
  final VoidCallback onExit;

  const EmojiShortcutPickerView(
    EmojiPickerConfig config,
    EmojiViewState state,
    this.editorState,
    this.onExit, {
    Key? key,
  }) : super(config, state, key: key);

  @override
  EmojiShortcutPickerViewState createState() => EmojiShortcutPickerViewState();
}

class EmojiShortcutPickerViewState extends State<EmojiShortcutPickerView>
    with TickerProviderStateMixin {
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
  final EmojiCategoryGroup searchEmojiList =
      EmojiCategoryGroup(EmojiCategory.SEARCH, <Emoji>[]);
  final _focusNode = FocusNode(debugLabel: 'popup_list_widget');

  PageController? _pageController;
  int _selectedIndex = 0;

  bool get isEmojiSearching =>
      searchEmojiList.emoji.isNotEmpty || _emojiController.text.isNotEmpty;

  @override
  void initState() {
    var initCategory = widget.state.emojiCategoryGroupList.indexWhere(
      (element) => element.category == widget.config.initCategory,
    );
    if (initCategory == -1) {
      initCategory = 0;
    }

    _pageController = PageController(initialPage: initCategory);
    _emojiFocusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _searchEmoji();
    });

    super.initState();
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _emojiFocusNode.dispose();
    _pageController!.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Handle arrow keys
    else if (arrowKeys[event.logicalKey] != null) {
      // Computing new emoji selection index
      final int newSelectedIndex =
          (_selectedIndex + arrowKeys[event.logicalKey]!)
              .clamp(0, searchEmojiList.emoji.length - 1);

      if (_selectedIndex == newSelectedIndex) return KeyEventResult.ignored;
      setState(() => _selectedIndex = newSelectedIndex);
      return KeyEventResult.handled;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onExit();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter || LogicalKeyboardKey.tab:
        if (searchEmojiList.emoji.isNotEmpty) {
          widget.state.onEmojiSelected(
              EmojiCategory.SEARCH, searchEmojiList.emoji[_selectedIndex]);

          // Insert actual emoji
          final selection = widget.editorState.selection;
          if (selection != null && !selection.isCollapsed) {
            final node = widget.editorState.getNodeAtPath(selection.end.path);
            if (node != null && node.delta != null) {
              widget.editorState.apply(
                widget.editorState.transaction
                  ..deleteText(
                    node,
                    selection.start.offset - _emojiController.text.length,
                    _emojiController.text.length,
                  ),
              );
            }
          }
        }

        widget.onExit();

        return KeyEventResult.handled;

      case LogicalKeyboardKey.backspace:
        widget.editorState.deleteBackward();
        if (_emojiController.text.isEmpty) {
          widget.onExit();
          return KeyEventResult.handled;
        }

        _emojiController.text = _emojiController.text
            .substring(0, _emojiController.text.length - 1);
        _searchEmoji();
        return KeyEventResult.handled;

      default:
        if (event.character == null) return KeyEventResult.ignored;

        widget.editorState.insertTextAtCurrentSelection(event.character!);

        if (event.character == ':') {
          widget.onExit();
          return KeyEventResult.handled;
        }
        _emojiController.text += event.character!;
        _searchEmoji();
        return KeyEventResult.handled;
    }
  }

  void _searchEmoji() {
    final String query =
        _emojiController.text.toLowerCase().replaceAll(" ", "_");

    searchEmojiList.emoji.clear();

    searchEmojiList.emoji.addAll(
      widget.state.emojiCategoryGroupList[0].emoji.where(
        (item) => query.isEmpty || item.name.toLowerCase().contains(query),
      ),
    );

    int remaingSpace = resultsFilterCount - searchEmojiList.emoji.length;
    int emojiCategoryIndex = 0;

    while (++emojiCategoryIndex < widget.state.emojiCategoryGroupList.length &&
        remaingSpace > 0) {
      searchEmojiList.emoji.addAll(
        widget.state.emojiCategoryGroupList[emojiCategoryIndex].emoji
            .where(
              (item) =>
                  searchEmojiList.emoji.firstWhereOrNull(
                          (sitem) => item.name == sitem.name) ==
                      null &&
                  (query.isEmpty || item.name.toLowerCase().contains(query)),
            )
            .take(remaingSpace ~/
                (widget.state.emojiCategoryGroupList.length -
                    emojiCategoryIndex)),
      );
      remaingSpace = resultsFilterCount - searchEmojiList.emoji.length;
    }
    setState(() {});
  }

  Widget _buildPage(double emojiSize) {
    final scrollController = ScrollController();

    // Build page normally
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: scrollController,
      barSize: 4.0,
      scrollbarPadding: const EdgeInsets.symmetric(horizontal: 5.0),
      handleColor: const Color(0xffDFE0E0),
      trackColor: const Color(0xffDFE0E0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: GridView.builder(
            cacheExtent: 10,
            controller: scrollController,
            padding: const EdgeInsets.all(0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.config.emojiNumberPerRow,
              mainAxisSpacing: widget.config.verticalSpacing,
              crossAxisSpacing: widget.config.horizontalSpacing,
            ),
            itemCount: searchEmojiList.emoji.length,
            // _buildEmoji
            itemBuilder: (context, index) => _buildButtonWidget(
                  onPressed: () {
                    widget.state.onEmojiSelected(
                        EmojiCategory.SEARCH, searchEmojiList.emoji[index]);
                    widget.onExit();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: Corners.s8Border,
                      color: index == _selectedIndex
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        searchEmojiList.emoji[index].emoji,
                        textScaleFactor: 1.0,
                        style: TextStyle(
                          fontSize: emojiSize,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: _onKey,
      focusNode: _focusNode,
      child: LayoutBuilder(builder: (context, constraints) {
        return Container(
          color: widget.config.bgColor,
          padding: const EdgeInsets.all(5.0),
          child: Flexible(
            child: searchEmojiList.emoji.isNotEmpty
                ? _buildPage(widget.config.getEmojiSize(constraints.maxWidth))
                : Center(
                    child: Text(
                      widget.config.noEmojiFoundText,
                      style: widget.config.noRecentsStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildButtonWidget({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    if (widget.config.buttonMode == ButtonMode.MATERIAL) {
      return InkWell(
        onTap: onPressed,
        child: child,
      );
    }
    return GestureDetector(
      onTap: onPressed,
      child: child,
    );
  }
}
