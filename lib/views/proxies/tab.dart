import 'dart:async';
import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';
import 'common.dart';

class ProxiesTabView extends ConsumerStatefulWidget {
  const ProxiesTabView({super.key});

  static Map<String, PageStorageKey> pageListStoreMap = {};

  @override
  ConsumerState<ProxiesTabView> createState() => ProxiesTabViewState();
}

class ProxiesTabViewState extends ConsumerState<ProxiesTabView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final _hasMoreButtonNotifier = ValueNotifier<bool>(false);
  final Map<String, ScrollController> _scrollControllers = {};
  int _columns = 1;

  @override
  void initState() {
    super.initState();
    ref.listenManual(proxiesTabControllerStateProvider, (prev, next) {
      if (prev == next) {
        return;
      }
      if (!stringListEquality.equals(prev?.groupNames, next.groupNames)) {
        final groupNames = next.groupNames;
        final currentGroupName = next.currentGroupName;
        final index = groupNames.indexWhere((item) => item == currentGroupName);
        _updateTabController(groupNames.length, index);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _destroyTabController();
    _hasMoreButtonNotifier.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _scrollControllerOf(String groupName) {
    return _scrollControllers.putIfAbsent(groupName, ScrollController.new);
  }

  // The page of a dropped group still holds its controller until this frame
  // unmounts it.
  void _pruneScrollControllers(List<Group> groups) {
    final names = {for (final group in groups) group.name};
    final dropped = [
      for (final entry in _scrollControllers.entries)
        if (!names.contains(entry.key)) entry,
    ];
    for (final entry in dropped) {
      _scrollControllers.remove(entry.key);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => entry.value.dispose(),
      );
    }
  }

  void scrollToGroupSelected() {
    final group = currentGroup;
    final controller = _scrollControllers[group?.name];
    if (group == null || controller == null) {
      return;
    }
    final cardType = ref.read(proxiesTabStateProvider).proxyCardType;
    final rowOffset = selectedRowOffset(
      proxies: group.all,
      selectedProxyName: ref.read(selectedProxyNameProvider(group.name)),
      columns: _columns,
      rowExtent: _columns == 1
          ? groupedProxyRowHeight(cardType) + 1
          : getRowExtent(cardType),
    );
    if (rowOffset == null) {
      return;
    }
    animateScrollTo(controller, rowOffset + (_columns == 1 ? 44 : 0));
  }

  Future<void> delayTestCurrentGroup() async {
    final group = currentGroup;
    if (group == null) {
      return;
    }
    await ref
        .read(proxiesActionProvider.notifier)
        .delayTestPageGroup(group.name);
  }

  Group? get currentGroup {
    return _getGroup(_tabController?.index);
  }

  Group? _getGroup(int? index) {
    final groups = ref.read(proxiesTabStateProvider).groups;
    if (index == null || index < 0 || index >= groups.length) {
      return null;
    }
    return groups[index];
  }

  Widget _buildMoreButton() {
    return Consumer(
      builder: (_, ref, _) {
        final isMobileView = ref.watch(isMobileViewProvider);
        return IconButton(
          tooltip: context.appLocalizations.more,
          onPressed: _showMoreMenu,
          iconSize: 20,
          icon: isMobileView
              ? const GlyphIcon(AppGlyphs.chevronDown)
              : const GlyphIcon(AppGlyphs.chevronForward),
        );
      },
    );
  }

  // A mask rather than a surface-colored cover holds on any page background;
  // at full scroll the fade lands in the last tab's trailing label padding.
  Shader _buildTabsMask(Rect bounds, bool hasMore) {
    final coverStart = bounds.width - kMinInteractiveDimension;
    final fadeStart = coverStart - kTabLabelPadding.right;
    if (!hasMore || fadeStart <= 0) {
      return const LinearGradient(
        colors: [Colors.black, Colors.black],
      ).createShader(bounds);
    }
    return LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [Colors.black, Colors.transparent],
      stops: [fadeStart / bounds.width, coverStart / bounds.width],
    ).createShader(bounds, textDirection: Directionality.of(context));
  }

  void _showMoreMenu() {
    showSheet(
      context: context,
      props: const SheetProps(isScrollControlled: false),
      builder: (_) {
        return CommonScaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              padding: const EdgeInsets.all(
                16,
              ).copyWith(top: context.contentTopPadding),
              child: Consumer(
                builder: (_, ref, _) {
                  final state = ref.watch(proxiesTabControllerStateProvider);
                  final groupNames = state.groupNames;
                  final currentGroupName = state.currentGroupName;
                  return SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 8,
                      spacing: 8,
                      children: [
                        for (final groupName in groupNames)
                          SettingTextCard(
                            groupName,
                            onPressed: () {
                              final index = groupNames.indexWhere(
                                (item) => item == groupName,
                              );
                              if (index == -1) return;
                              _tabController?.animateTo(index);
                              ref
                                  .read(proxiesActionProvider.notifier)
                                  .updateCurrentGroupName(groupName);
                              Navigator.of(context).pop();
                            },
                            isSelected: groupName == currentGroupName,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          title: context.appLocalizations.proxyGroup,
        );
      },
    );
  }

  void _tabControllerListener([int? index]) {
    final group = _getGroup(index ?? _tabController?.index);
    if (group == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(proxiesActionProvider.notifier)
          .updateCurrentGroupName(group.name);
    });
  }

  void _destroyTabController() {
    _tabController?.removeListener(_tabControllerListener);
    _tabController?.dispose();
    _tabController = null;
  }

  // An empty group list keeps the previous controller: the outgoing tab bar
  // still drives it while the empty state animates in.
  void _updateTabController(int length, int index) {
    if (length == 0) {
      return;
    }
    _destroyTabController();
    final realIndex = index == -1 ? 0 : index;
    final controller = TabController(
      length: length,
      initialIndex: realIndex,
      vsync: this,
    );
    _tabController = controller;
    _tabControllerListener(realIndex);
    controller.addListener(_tabControllerListener);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    ref.watch(themeSettingProvider.select((state) => state.textScale));
    final state = ref.watch(proxiesTabStateProvider.select((state) => state));
    final proxiesLayout = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.layout),
    );
    final isSearching = ref.watch(
      queryProvider(
        QueryTag.proxies,
      ).select((query) => SearchQuery(query).isNotEmpty),
    );
    final groups = state.groups;
    final selectedGroupName = ref.watch(
      proxiesTabControllerStateProvider.select(
        (value) => value.currentGroupName,
      ),
    );
    final selectedGroup =
        groups.where((group) => group.name == selectedGroupName).firstOrNull ??
        groups.firstOrNull;
    _pruneScrollControllers(groups);
    return NullStatusSwitcher(
      isEmpty: groups.isEmpty || _tabController == null,
      isSearching: isSearching,
      nullStatus: NullStatus(
        illustration: NullStatusIllustration.proxies,
        label: appLocalizations.nullTip(appLocalizations.proxies),
      ),
      child: AppBarClearance(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedGroup case final group?)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: _ProxyGroupSummary(
                  group: group,
                  onTest: delayTestCurrentGroup,
                ),
              ),
            NotificationListener<ScrollMetricsNotification>(
              onNotification: (scrollNotification) {
                _hasMoreButtonNotifier.value =
                    scrollNotification.metrics.maxScrollExtent > 0;
                return false;
              },
              child: ValueListenableBuilder(
                valueListenable: _hasMoreButtonNotifier,
                builder: (_, hasMore, moreButton) {
                  final showMore = hasMore && groups.length > 3;
                  final scheme = context.colorScheme;
                  return Stack(
                    alignment: AlignmentDirectional.centerEnd,
                    children: [
                      Positioned.fill(
                        left: 20,
                        right: 20,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: scheme.surfaceContainer,
                            shape: AppShape.sm,
                          ),
                        ),
                      ),
                      ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) =>
                            _buildTabsMask(bounds, showMore),
                        child: TabBar(
                          controller: _tabController,
                          padding: EdgeInsetsDirectional.only(
                            start: 23,
                            top: 3,
                            bottom: 3,
                            end: showMore ? kMinInteractiveDimension : 23,
                          ),
                          dividerColor: Colors.transparent,
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: ShapeDecoration(
                            gradient: scheme.interfaceGradient(),
                            shape: AppShape.sm.copyWith(
                              side: BorderSide(
                                color: scheme.outlineVariant,
                                width: 0.5,
                              ),
                            ),
                            shadows: scheme.interfaceShadows(),
                          ),
                          labelStyle: context.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          labelColor: scheme.primary,
                          unselectedLabelColor: scheme.onSurfaceVariant,
                          isScrollable: groups.length > 3,
                          tabAlignment: groups.length > 3
                              ? TabAlignment.start
                              : TabAlignment.fill,
                          tabs: [
                            for (final group in groups)
                              Tab(
                                height: 30,
                                child: Builder(
                                  builder: (context) {
                                    return EmojiText(
                                      group.name,
                                      style: DefaultTextStyle.of(context).style,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (showMore) moreButton!,
                    ],
                  );
                },
                child: _buildMoreButton(),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final columns = context.isMobileView
                      ? 1
                      : getProxiesColumns(
                          max(constraints.maxWidth - 32, 0),
                          proxiesLayout,
                        );
                  _columns = columns;
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      for (final group in groups)
                        ProxyGroupView(
                          key: ValueKey(group.name),
                          controller: _scrollControllerOf(group.name),
                          group: group,
                          columns: columns,
                          cardType: state.proxyCardType,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProxyGroupSummary extends ConsumerWidget {
  const _ProxyGroupSummary({required this.group, required this.onTest});
  final Group group;
  final VoidCallback onTest;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final selected = ref
        .watch(realSelectedProxyStateProvider(group.name))
        .proxyName;
    final testing = ref.watch(
      delayTestingGroupsProvider.select(
        (groups) => groups.contains(group.name),
      ),
    );
    final labels = context.appLocalizations;
    return CommonCard(
      radius: AppCorner.lg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                shape: AppShape.sm,
              ),
              child: SizedBox.square(
                dimension: 32,
                child: GlyphIcon(
                  AppGlyphs.proxies,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmojiText(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${ref.watch(isStartProvider) ? labels.currentNode : labels.selectedNode} · ${selected.isNotEmpty ? selected : '—'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: testing ? null : onTest,
              style: TextButton.styleFrom(
                backgroundColor: scheme.primary.withValues(alpha: 0.05),
                minimumSize: const Size(52, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: testing
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Text(
                      labels.delayTest,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProxyGroupView extends ConsumerWidget {
  final Group group;
  final ScrollController controller;
  final int columns;
  final ProxyCardType cardType;
  final bool picker;

  const ProxyGroupView({
    super.key,
    required this.group,
    required this.controller,
    required this.columns,
    required this.cardType,
    this.picker = false,
  });

  Widget _groupedList(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final proxies = group.all;
    return CommonScrollBar(
      controller: controller,
      thumbVisibility: true,
      child: CustomScrollView(
        key: _getPageStorageKey(ref),
        controller: controller,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              18 + BottomInsetScope.of(context),
            ),
            sliver: DecoratedSliver(
              decoration: ShapeDecoration(
                gradient: picker ? null : scheme.interfaceGradient(),
                shape: AppShape.lg.copyWith(
                  side: picker
                      ? BorderSide.none
                      : BorderSide(color: scheme.outlineVariant, width: 0.6),
                ),
                shadows: picker ? null : scheme.interfaceShadows(),
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              picker
                                  ? context.appLocalizations.nodes
                                  : context.appLocalizations.nodesCount(
                                      proxies.length,
                                    ),
                              style: context.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            context.appLocalizations.delay,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    sliver: SliverList.separated(
                      itemCount: proxies.length,
                      itemBuilder: (context, index) => SizedBox(
                        height:
                            groupedProxyRowHeight(cardType) - (picker ? 6 : 0),
                        child: ProxyCard(
                          testUrl: group.testUrl,
                          groupType: group.type,
                          type: cardType,
                          compact: true,
                          grouped: true,
                          proxy: proxies[index],
                          groupName: group.name,
                        ),
                      ),
                      separatorBuilder: (_, _) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 60,
                          end: 12,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: scheme.outlineVariant.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageStorageKey _getPageStorageKey(WidgetRef ref) {
    final profile = ref.read(currentProfileProvider);
    final key =
        '${profile?.id}_${ScrollPositionCacheKey.proxiesTabList.name}_${group.name}';
    return ProxiesTabView.pageListStoreMap.updateCacheValue(
      key,
      () => PageStorageKey(key),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxies = group.all;
    if (columns == 1) return _groupedList(context, ref);
    return CommonScrollBar(
      controller: controller,
      thumbVisibility: true,
      child: GridView.builder(
        key: _getPageStorageKey(ref),
        controller: controller,
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 16 + BottomInsetScope.of(context),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: proxyGridSpacing,
          crossAxisSpacing: 8,
          mainAxisExtent: getItemHeight(cardType),
        ),
        itemCount: proxies.length,
        itemBuilder: (_, index) {
          final proxy = proxies[index];
          return ProxyCard(
            testUrl: group.testUrl,
            groupType: group.type,
            type: cardType,
            proxy: proxy,
            groupName: group.name,
          );
        },
      ),
    );
  }
}
