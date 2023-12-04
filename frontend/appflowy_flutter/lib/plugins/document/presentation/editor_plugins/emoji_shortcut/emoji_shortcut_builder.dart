import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker_builder.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_view_state.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_category_models.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_model.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int emojiNumberPerRow = 8;
const double emojiSizeMax = 40;
const resultsFilterCount = 35;

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
  TabController? _tabController;
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

    _tabController = TabController(
      initialIndex: initCategory,
      length: widget.state.emojiCategoryGroupList.length,
      vsync: this,
    );

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
    _tabController!.dispose();
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
      if (_selectedIndex != newSelectedIndex) {
        setState(() => _selectedIndex = newSelectedIndex);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape || LogicalKeyboardKey.tab:
        widget.onExit();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.space:
        widget.editorState.insertTextAtCurrentSelection(" ");
        _emojiController.text += " ";
        searchEmojiList.emoji.isEmpty ? widget.onExit() : _searchEmoji();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
        searchEmojiList.emoji.isEmpty
            ? widget.editorState.insertNewLine(
                position: widget.editorState.selection as Position)
            : widget.state.onEmojiSelected(
                EmojiCategory.SEARCH,
                searchEmojiList.emoji[_selectedIndex],
              );

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
        _emojiController.text += event.character!;
        _searchEmoji();
        widget.editorState.insertTextAtCurrentSelection(event.character!);
        return KeyEventResult.handled;
    }
  }

  void _searchEmoji() {
    final String query =
        _emojiController.text.toLowerCase().replaceAll(" ", "_");

    searchEmojiList.emoji.clear();

    searchEmojiList.emoji.addAll(widget.state.emojiCategoryGroupList[0].emoji
        .where((item) => item.name.toLowerCase().contains(query)));

    int remaingSpace = resultsFilterCount - searchEmojiList.emoji.length;

    if (remaingSpace > 0) {
      searchEmojiList.emoji.addAll(
        widget.state.emojiCategoryGroupList[9].emoji
            .where((item) => item.name.toLowerCase().contains(query))
            .toList()
            .take(remaingSpace),
      );

      remaingSpace = resultsFilterCount - searchEmojiList.emoji.length;
      int emojiCategoryIndex = widget.state.emojiCategoryGroupList.length - 2;
      int categoryRatio = (remaingSpace / (emojiCategoryIndex)) as int;

      while (emojiCategoryIndex > 0 && remaingSpace > 0) {
        searchEmojiList.emoji.addAll(widget
            .state.emojiCategoryGroupList[emojiCategoryIndex].emoji
            .where((item) =>
                searchEmojiList.emoji.contains(item) &&
                (query.isEmpty || item.name.toLowerCase().contains(query)))
            .take(categoryRatio));

        emojiCategoryIndex--;
        remaingSpace = resultsFilterCount - searchEmojiList.emoji.length;
        categoryRatio = (remaingSpace / (emojiCategoryIndex)) as int;
      }
    }

    setState(() {});
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

  Widget? _buildPage(double emojiSize) {
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
          itemBuilder: (context, index) => _buildEmoji(
            emojiSize,
            searchEmojiList,
            searchEmojiList.emoji[index],
            index == _selectedIndex
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildEmoji(
    double emojiSize,
    EmojiCategoryGroup categoryEmoji,
    Emoji emoji,
    Color color,
  ) {
    return _buildButtonWidget(
      onPressed: () {
        widget.state.onEmojiSelected(categoryEmoji.category, emoji);
        widget.onExit();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: Corners.s8Border,
          color: color,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            emoji.emoji,
            textScaleFactor: 1.0,
            style: TextStyle(
              fontSize: emojiSize,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: _onKey,
      focusNode: _focusNode,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final emojiSize = widget.config.getEmojiSize(constraints.maxWidth);

          return Visibility(
            visible: searchEmojiList.emoji.isNotEmpty,
            child: Container(
              color: widget.config.bgColor,
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Flexible(
                    child: PageView.builder(
                      itemCount: 1,
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, __) => _buildPage(emojiSize),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
