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
      onKeywordsUpdate: _listController.updateKeywords,
      searchState: AppBarSearchState(onSearch: _listController.search),
      iconActions: _buildActions(),
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _listController,
        builder: (context, state, _) {
          final connections = state.list;
          return Column(
            children: [
              _ConnectionSummary(connections: connections),
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
            dimension: 44,
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
  const _ConnectionSummary({required this.connections});

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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, context.contentTopPadding, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            '${context.appLocalizations.connections} · ${connections.length}',
            style: context.textTheme.titleSmall,
          ),
          Text(
            '↑ ${up.traffic.show}/s   ↓ ${down.traffic.show}/s',
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
