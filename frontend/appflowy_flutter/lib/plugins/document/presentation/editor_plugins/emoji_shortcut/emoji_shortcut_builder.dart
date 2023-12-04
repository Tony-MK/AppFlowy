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

    while (widget.state.emojiCategoryGroupList[initCategory].emoji.isEmpty &&
        initCategory < widget.state.emojiCategoryGroupList.length) {
      initCategory++;
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
      //_searchEmoji();
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
    final catEmoji = isEmojiSearching
        ? searchEmojiList
        : widget.state.emojiCategoryGroupList[_tabController!.index];

    final List<Emoji> showingItems = catEmoji.emoji;

    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Handle arrow keys
    else if (arrowKeys[event.logicalKey] != null) {
      // Computing new emoji selection index
      final int newSelectedIndex =
          (_selectedIndex + arrowKeys[event.logicalKey]!)
              .clamp(0, showingItems.length - 1);
      if (newSelectedIndex != _selectedIndex) {
        setState(() => _selectedIndex = newSelectedIndex);
      }
      return KeyEventResult.handled;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        widget.onExit();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.space || LogicalKeyboardKey.tab:
        if (_emojiController.text.isEmpty || showingItems.isEmpty) {
          widget.onExit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;

      case LogicalKeyboardKey.enter:
        if (showingItems.isNotEmpty) {
          if (_emojiController.text.isNotEmpty) {
            _deleteLastCharacters(_emojiController.text.length);
          }
          widget.state.onEmojiSelected(
            EmojiCategory.SEARCH,
            showingItems[_selectedIndex],
          );
        }

        widget.onExit();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.backspace:
        _deleteLastCharacters(1);
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

    int emojiCategoryIndex = 0;

    searchEmojiList.emoji.clear();

    while (emojiCategoryIndex < widget.state.emojiCategoryGroupList.length) {
      searchEmojiList.emoji.addAll((query.isEmpty
              ? widget.state.emojiCategoryGroupList[emojiCategoryIndex].emoji
              : widget.state.emojiCategoryGroupList[emojiCategoryIndex].emoji
                  .where((item) => item.name.toLowerCase().contains(query)))
          .toList()
          .take(resultsFilterCount));
      emojiCategoryIndex++;
    }

    setState(() {});
  }

  void _deleteLastCharacters(int nChars) {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node != null && delta != null) {
      widget.editorState.apply(widget.editorState.transaction
        ..deleteText(
          node,
          selection.start.offset - nChars,
          nChars,
        ));
    }
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

  Widget? _buildPage(double emojiSize, EmojiCategoryGroup categoryEmoji) {
    // Display notice if recent has no entries yet
    final scrollController = ScrollController();

    if (categoryEmoji.category == EmojiCategory.RECENT &&
        categoryEmoji.emoji.isEmpty) {
      return _buildNoRecent();
    } else if (categoryEmoji.category == EmojiCategory.SEARCH &&
        categoryEmoji.emoji.isEmpty) {
      return null;
    }
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
          controller: scrollController,
          padding: const EdgeInsets.all(0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.config.emojiNumberPerRow,
            mainAxisSpacing: widget.config.verticalSpacing,
            crossAxisSpacing: widget.config.horizontalSpacing,
          ),
          itemCount: categoryEmoji.emoji.length,
          itemBuilder: (context, index) {
            final item = categoryEmoji.emoji[index];
            return _buildEmoji(
              emojiSize,
              categoryEmoji,
              item,
              index == _selectedIndex,
            );
          },
          cacheExtent: 10,
        ),
      ),
    );
  }

  Widget _buildEmoji(
    double emojiSize,
    EmojiCategoryGroup categoryEmoji,
    Emoji emoji,
    bool isSelected,
  ) {
    return _buildButtonWidget(
      onPressed: () {
        widget.state.onEmojiSelected(categoryEmoji.category, emoji);
        widget.onExit();
        _deleteLastCharacters(1);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: Corners.s8Border,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
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

  Widget _buildNoRecent() {
    return Center(
      child: Text(
        widget.config.noRecentsText,
        style: widget.config.noRecentsStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final emojiSize = widget.config.getEmojiSize(constraints.maxWidth);

          return Visibility(
            visible: _emojiController.text.isNotEmpty,
            child: Container(
              color: widget.config.bgColor,
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Flexible(
                    child: PageView.builder(
                      itemCount: searchEmojiList.emoji.isNotEmpty
                          ? 1
                          : widget.state.emojiCategoryGroupList.length,
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        _tabController!.animateTo(
                          index,
                          duration: widget.config.tabIndicatorAnimDuration,
                        );
                      },
                      itemBuilder: (context, index) {
                        final EmojiCategoryGroup catEmoji = isEmojiSearching
                            ? searchEmojiList
                            : widget.state.emojiCategoryGroupList[index];

                        return _buildPage(emojiSize, catEmoji);
                      },
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
