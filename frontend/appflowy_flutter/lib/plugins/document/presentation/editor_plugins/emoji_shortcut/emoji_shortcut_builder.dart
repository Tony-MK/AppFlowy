import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker_builder.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_view_state.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_category_models.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_model.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int emojiNumberPerRow = 8;
const double emojiSizeMax = 40;

final arrowKeys = {
  LogicalKeyboardKey.arrowRight: 1,
  LogicalKeyboardKey.arrowLeft: -1,
  LogicalKeyboardKey.arrowDown: emojiNumberPerRow,
  LogicalKeyboardKey.arrowUp: -emojiNumberPerRow,
  LogicalKeyboardKey.tab: emojiNumberPerRow,
};

class ShortcutEmojiPickerView extends EmojiPickerBuilder {
  final EditorState editorState;
  final VoidCallback onExit;

  const ShortcutEmojiPickerView(
    EmojiPickerConfig config,
    EmojiViewState state,
    this.editorState,
    this.onExit, {
    Key? key,
  }) : super(config, state, key: key);

  @override
  ShortcutEmojiPickerViewState createState() => ShortcutEmojiPickerViewState();
}

class ShortcutEmojiPickerViewState extends State<ShortcutEmojiPickerView>
    with TickerProviderStateMixin {
  PageController? _pageController;
  TabController? _tabController;
  final TextEditingController _emojiController = TextEditingController();
  final FocusNode _emojiFocusNode = FocusNode();
  EmojiCategoryGroup searchEmojiList =
      EmojiCategoryGroup(EmojiCategory.SEARCH, <Emoji>[]);
  final _focusNode = FocusNode(debugLabel: 'popup_list_widget');
  int _selectedIndex = 0;
  final Color selectedItemColor = const Color(0xFFE0F8FF);
  final resultsFilterCount = 35;

  bool get isEmojiSearching =>
      searchEmojiList.emoji.isNotEmpty || _emojiController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
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
    });
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _emojiFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    final catEmoji = isEmojiSearching
        ? searchEmojiList
        : widget.state.emojiCategoryGroupList[_tabController!.index];

    final List<Emoji> showingItems = catEmoji.emoji;
    Log.keyboard.debug('colon command, on key $event');
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final arrowKeys = [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.tab
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_emojiController.text.isEmpty) {
        widget.onExit();
        return KeyEventResult.ignored;
      }
      if (showingItems.isEmpty) {
        return KeyEventResult.handled;
      }
      _deleteLastCharacters(length: _emojiController.text.length + 1);

      widget.state.onEmojiSelected(
        EmojiCategory.SEARCH,
        showingItems[_selectedIndex],
      );
      widget.onExit();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onExit();

      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_emojiController.text.isEmpty) {
        widget.onExit();
      }
      return KeyEventResult.ignored;
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_emojiController.text.isEmpty) {
        widget.onExit();
      } else {
        _emojiController.text = _emojiController.text
            .substring(0, _emojiController.text.length - 1);
        _searchEmoji();
      }
      _deleteLastCharacters();
      return KeyEventResult.handled;
    } else if (event.character != null &&
        !arrowKeys.contains(event.logicalKey)) {
      _emojiController.text += event.character!;
      _searchEmoji();
      widget.editorState.insertTextAtCurrentSelection(event.character!);
      return KeyEventResult.handled;
    }

    var newSelectedIndex = _selectedIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newSelectedIndex -= 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newSelectedIndex += 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newSelectedIndex -= widget.config.emojiNumberPerRow;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newSelectedIndex += widget.config.emojiNumberPerRow;
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      newSelectedIndex += widget.config.emojiNumberPerRow;
      ;
      final currRow = (newSelectedIndex) % widget.config.emojiNumberPerRow;
      if (newSelectedIndex >= showingItems.length) {
        newSelectedIndex = (currRow + 1) % widget.config.emojiNumberPerRow;
      }
    }

    if (newSelectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newSelectedIndex.clamp(0, showingItems.length - 1);
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _searchEmoji() {
    final String query = _emojiController.text.toLowerCase();

    searchEmojiList.emoji.clear();
    for (final element in widget.state.emojiCategoryGroupList) {
      searchEmojiList.emoji.addAll(
        element.emoji.where((item) {
          return item.name.toLowerCase().replaceAll(" ", "_").contains(query);
        }).toList(),
      );
      searchEmojiList.emoji =
          searchEmojiList.emoji.take(resultsFilterCount).toList();
    }
    setState(() {});
  }

  void _deleteLastCharacters({int length = 1}) {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    // widget.onSelectionUpdate();
    final transaction = widget.editorState.transaction
      ..deleteText(
        node,
        selection.start.offset - length,
        length,
      );
    widget.editorState.apply(transaction);
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
