import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionsView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final Future<List<TrackerInfo>> Function()? connectionsReader;

  const ConnectionsView({
    super.key,
    this.scrollController,
    @visibleForTesting this.connectionsReader,
  });

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView>
    with
        WidgetsBindingObserver,
        ActivePollingMixin<ConnectionsView>,
        RouteMotionHoldMixin<ConnectionsView> {
  CoreController get _core => ref.read(coreHandlerProvider);

  final _listController = TrackerInfoListController();
  final _speedRanker = TrackerSpeedRanker();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  Duration get pollInterval => const Duration(seconds: 1);

  List<IconButtonData> _buildActions() {
    return [
      IconButtonData(
        glyph: AppGlyphs.clearAll,
        tooltip: context.appLocalizations.closeConnections,
        onPressed: () async {
          unawaited(_core.closeConnections());
          await _refreshConnections();
        },
      ),
    ];
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    final trackerInfos = await _readConnections();
    if (!isCurrent()) {
      return;
    }
    updateWhenRouteSettled(() => _applyConnections(trackerInfos));
  }

  Future<void> _refreshConnections() async {
    final trackerInfos = await _readConnections();
    if (!mounted) {
      return;
    }
    _applyConnections(trackerInfos);
  }

  Future<List<TrackerInfo>?> _readConnections() async {
    try {
      final connectionsReader = widget.connectionsReader;
      return connectionsReader != null
          ? await connectionsReader()
          : await _core.getConnections();
    } catch (error) {
      commonPrint.log(
        'updateConnections error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  void _applyConnections(List<TrackerInfo>? trackerInfos) {
    if (trackerInfos == null) {
      return;
    }
    _listController.setTrackerInfos(
      _speedRanker.rank(trackerInfos, DateTime.now()),
    );
  }

  Future<void> _handleBlockConnection(String id) async {
    await _core.closeConnection(id);
    await _refreshConnections();
  }

  @override
  void dispose() {
    _listController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: PageLabel.connections.label,
      actionSize: context.isMobileView
          ? TonalButtonSize.interface
          : TonalButtonSize.bar,
      titleWidget: ProfilePageTitle(title: context.appLocalizations.connection),
      dockSearchInSheet: false,
      toolbarHeight: context.isMobileView ? 80 : null,
      onKeywordsUpdate: _listController.updateKeywords,
      searchState: AppBarSearchState(onSearch: _listController.search),
      iconActions: context.isMobileView ? const [] : _buildActions(),
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _listController,
        builder: (context, state, _) {
          final connections = state.list;
          return Column(
            children: [
              _ConnectionSummary(
                connections: connections,
                onCloseAll: _buildActions().first.onPressed,
              ),
              Expanded(
                child: NullStatusSwitcher(
                  isEmpty: connections.isEmpty,
                  isSearching: state.isSearching,
                  nullStatus: NullStatus(
                    label: appLocalizations.nullTip(
                      appLocalizations.connections,
                    ),
                    illustration: NullStatusIllustration.connections,
                  ),
                  child: TrackerInfoAnimatedList(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: 0,
                      bottom: 16 + BottomInsetScope.of(context),
                    ),
                    trackerInfos: connections,
                    detailTitle: appLocalizations.details(
                      appLocalizations.connection,
                    ),
                    actionBuilder: (trackerInfo) => _BlockConnectionButton(
                      onPressed: () {
                        _handleBlockConnection(trackerInfo.id);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// One per live row: an IconButton would add a theme animation to each.
class _BlockConnectionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BlockConnectionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.appLocalizations.blockConnection,
      child: Semantics(
        button: true,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: SizedBox.square(
            dimension: 32,
            child: Center(
              child: GlyphIcon(
                AppGlyphs.block,
                size: 16,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.connections, this.onCloseAll});
  final VoidCallback? onCloseAll;

  final List<TrackerInfo> connections;

  @override
  Widget build(BuildContext context) {
    final up = connections.fold<int>(
      0,
      (value, item) => value + (item.uploadSpeed ?? 0),
    );
    final down = connections.fold<int>(
      0,
      (value, item) => value + (item.downloadSpeed ?? 0),
    );
    final scheme = context.colorScheme;
    Widget rate(Glyph glyph, int value) {
      final display = value.traffic;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GlyphIcon(glyph, size: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: display.value,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: ' ${display.unit}/s',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        context.appBarInset + (context.isMobileView ? 12 : 28),
        20,
        16,
      ),
      child: CommonCard(
        radius: AppCorner.lg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.appLocalizations.realTimeTraffic,
                      style: context.textTheme.labelSmall?.copyWith(
                        height: 1.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  CommonPopupBox(
                    targetBuilder: (open) => GestureDetector(
                      onTap: () => open(offset: Offset.zero),
                      child: Tooltip(
                        message: context.appLocalizations.closeConnections,
                        child: Text(
                          context.appLocalizations.activeConnectionCount(
                            connections.length,
                          ),
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            height: 1.2,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    popupBuilder: (_) => CommonPopupMenu(
                      items: [
                        CommonPopupMenuItem(
                          label: context.appLocalizations.closeConnections,
                          glyph: AppGlyphs.clearAll,
                          onPressed: onCloseAll,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: rate(AppGlyphs.arrowUp, up)),
                  const SizedBox(width: 24),
                  Expanded(child: rate(AppGlyphs.arrowDown, down)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
