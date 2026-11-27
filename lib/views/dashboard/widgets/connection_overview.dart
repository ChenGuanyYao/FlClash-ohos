import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/proxies.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionOverview extends ConsumerWidget {
  const ConnectionOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final labels = context.appLocalizations;
    final running = ref.watch(isStartProvider);
    final suspended = running && ref.watch(suspendProvider);
    final active = running && !suspended;
    final hasProfile = ref.watch(
      profilesProvider.select((value) => value.isNotEmpty),
    );
    final profile = ref.watch(currentProfileProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((value) => value.mode),
    );
    final groups = ref.watch(groupsProvider);
    final groupStates = ref.watch(currentGroupsStateProvider).value;
    final visible = mode == Mode.global
        ? groupStates
              .where((group) => group.name == GroupName.GLOBAL.name)
              .toList()
        : groupStates;
    final preferred = profile?.currentGroupName;
    final group =
        visible.where((item) => item.name == preferred).firstOrNull ??
        visible.firstOrNull;
    final resolved = group == null
        ? null
        : ref.watch(realSelectedProxyStateProvider(group.name));
    final nodeName = resolved?.proxyName ?? '';
    final node = groups
        .expand((item) => item.all)
        .where((item) => item.name == nodeName)
        .firstOrNull;
    final unresolved =
        nodeName.isEmpty || groups.any((item) => item.name == nodeName);
    final title = !hasProfile
        ? labels.addProfile
        : mode == Mode.direct
        ? labels.direct
        : unresolved
        ? labels.noInfo
        : nodeName;
    final status = suspended
        ? labels.suspended
        : running
        ? labels.connected
        : labels.disconnected;
    final action = !hasProfile
        ? labels.addProfile
        : running
        ? labels.disconnect
        : labels.connect;
    final statusColor = active
        ? scheme.connectionAccent
        : suspended
        ? scheme.suspendedAccent
        : scheme.onSurfaceVariant;
    void switchNode() {
      if (!hasProfile) {
        ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.profiles);
        return;
      }
      showSheet<void>(
        context: context,
        props: SheetProps(
          isScrollControlled: true,
          backdropBlur: 2.2,
          barrierColor: Theme.brightnessOf(context) == Brightness.dark
              ? const Color(0x56040C1A)
              : const Color(0x32040C1A),
        ),
        builder: (sheetContext) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.68,
          child: ProxiesView(title: labels.switchNode),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            gradient: scheme.interfaceGradient(raised: true),
            shape: AppShape.xl.copyWith(
              side: BorderSide(color: scheme.outlineVariant, width: 0.65),
            ),
            shadows: scheme.interfaceShadows(raised: true),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: ShapeDecoration(
                        color: statusColor,
                        shape: AppShape.full,
                      ),
                      child: const SizedBox.square(dimension: 6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (hasProfile && group != null)
                      SizedBox(
                        width:
                            97 *
                            MediaQuery.textScalerOf(
                              context,
                            ).scale(1).clamp(1, 1.5),
                        child: PopupMenuButton<String>(
                          tooltip: labels.proxyGroup,
                          onSelected: (name) => ref
                              .read(proxiesActionProvider.notifier)
                              .updateCurrentGroupName(name),
                          itemBuilder: (_) => [
                            for (final item in visible)
                              PopupMenuItem(
                                value: item.name,
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          child: Container(
                            decoration: ShapeDecoration(
                              color: scheme.primary.withValues(alpha: 0.05),
                              shape: AppShape.sm,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const GlyphIcon(
                                  AppGlyphs.chevronDown,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !hasProfile
                                ? labels.profiles
                                : mode == Mode.direct
                                ? labels.outboundMode
                                : active
                                ? labels.currentNode
                                : labels.selectedNode,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 7,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hasProfile &&
                                  group != null &&
                                  !unresolved &&
                                  active &&
                                  mode != Mode.direct)
                                _OverviewDelay(
                                  groupName: group.name,
                                  testUrl: group.testUrl,
                                ),
                              if (hasProfile &&
                                  node != null &&
                                  !unresolved &&
                                  mode != Mode.direct)
                                Text(
                                  node.type,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              if (hasProfile && running)
                                const _OverviewRuntime(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Transform.translate(
                      offset: const Offset(7, 17.5),
                      child: _OverviewPower(
                        running: running,
                        action: action,
                        glyph: !hasProfile
                            ? AppGlyphs.add
                            : suspended
                            ? AppGlyphs.wifiOff
                            : AppGlyphs.power,
                        onPressed: () {
                          if (!hasProfile) {
                            ref
                                .read(currentPageLabelProvider.notifier)
                                .toPage(PageLabel.profiles);
                            return;
                          }
                          ref
                              .read(commonActionProvider.notifier)
                              .toggleRunning();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox.shrink(),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: context.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    onPressed: !hasProfile
                        ? switchNode
                        : mode == Mode.direct
                        ? () => ref
                              .read(currentPageLabelProvider.notifier)
                              .toPage(PageLabel.connections)
                        : switchNode,
                    icon: Transform.flip(
                      flipX:
                          mode != Mode.direct &&
                          Directionality.of(context) == TextDirection.ltr,
                      child: GlyphIcon(
                        mode == Mode.direct
                            ? AppGlyphs.connections
                            : AppGlyphs.arrowBack,
                        size: 13,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    label: Text(
                      !hasProfile
                          ? labels.addProfile
                          : mode == Mode.direct
                          ? labels.connections
                          : labels.switchNode,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant,
                  thickness: 0.6,
                ),
                const SizedBox(height: 16),
                const _OverviewTraffic(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _OverviewMode(),
      ],
    );
  }
}

class _OverviewPower extends StatelessWidget {
  const _OverviewPower({
    required this.running,
    required this.action,
    required this.glyph,
    required this.onPressed,
  });
  final bool running;
  final String action;
  final Glyph glyph;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: action,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                colors: [scheme.outlineVariant, scheme.surfaceContainerLow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: AppShape.full,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FilledButton(
                style:
                    FilledButton.styleFrom(
                      minimumSize: const Size.square(72),
                      maximumSize: const Size.square(72),
                      padding: EdgeInsets.zero,
                      shape: AppShape.full,
                      foregroundColor: running
                          ? scheme.primary
                          : scheme.onPrimary,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: BorderSide(
                        color: running
                            ? scheme.outlineVariant
                            : scheme.primary.withValues(alpha: 0.25),
                        width: 0.65,
                      ),
                    ).copyWith(
                      backgroundBuilder: (context, states, child) =>
                          DecoratedBox(
                            decoration: ShapeDecoration(
                              gradient: running
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors:
                                          Theme.brightnessOf(context) ==
                                              Brightness.dark
                                          ? const [
                                              Color(0xFF3B4D69),
                                              Color(0xFF26354E),
                                            ]
                                          : const [
                                              Colors.white,
                                              Color(0xFFE9EFF9),
                                            ],
                                    )
                                  : scheme.interfaceGradient(
                                      color: scheme.primary,
                                      raised: true,
                                    ),
                              shape: AppShape.full,
                              shadows: states.contains(WidgetState.pressed)
                                  ? const []
                                  : scheme.interfaceShadows(raised: true),
                            ),
                            child: child,
                          ),
                    ),
                onPressed: onPressed,
                child: Semantics(
                  label: action,
                  child: GlyphIcon(glyph, size: 28, fill: 1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox.shrink(),
        Text(
          action,
          style: context.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OverviewDelay extends ConsumerWidget {
  const _OverviewDelay({required this.groupName, required this.testUrl});
  final String groupName;
  final String? testUrl;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = ref.watch(
      delayProvider(proxyName: groupName, testUrl: testUrl),
    );
    final scheme = context.colorScheme;
    final color = delay == null
        ? scheme.onSurfaceVariant
        : delay <= 0
        ? scheme.error
        : scheme.connectionAccent;
    return Tooltip(
      message: context.appLocalizations.delay,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color.withValues(alpha: 0.08),
          shape: AppShape.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            delay == null
                ? '—'
                : delay <= 0
                ? context.appLocalizations.timeout
                : '$delay ms',
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewRuntime extends ConsumerWidget {
  const _OverviewRuntime();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
    getTimeText(ref.watch(runTimeProvider)),
    style: context.textTheme.labelSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

class _OverviewTraffic extends ConsumerWidget {
  const _OverviewTraffic();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(trafficsProvider);
    final active = ref.watch(isStartProvider) && !ref.watch(suspendProvider);
    final traffic = active
        ? history.list.safeLast(const Traffic())
        : const Traffic();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _TrafficValue(
            glyph: AppGlyphs.arrowUp,
            label: context.appLocalizations.uploadRate,
            value: traffic.up,
            values: active
                ? [for (final item in history.list) item.up.toDouble()]
                : const [],
            revision: history.revision,
            capacity: history.maxLength,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _TrafficValue(
            glyph: AppGlyphs.arrowDown,
            label: context.appLocalizations.downloadRate,
            value: traffic.down,
            values: active
                ? [for (final item in history.list) item.down.toDouble()]
                : const [],
            revision: history.revision,
            capacity: history.maxLength,
          ),
        ),
      ],
    );
  }
}

class _TrafficValue extends StatelessWidget {
  const _TrafficValue({
    required this.glyph,
    required this.label,
    required this.value,
    required this.values,
    required this.revision,
    required this.capacity,
  });
  final Glyph glyph;
  final String label;
  final num value;
  final List<double> values;
  final int revision;
  final int capacity;
  @override
  Widget build(BuildContext context) {
    final display = value.traffic;
    final scheme = context.colorScheme;
    final color = glyph == AppGlyphs.arrowUp
        ? (Theme.brightnessOf(context) == Brightness.dark
              ? const Color(0xFFD7B17D)
              : const Color(0xFFB78C58))
        : (Theme.brightnessOf(context) == Brightness.dark
              ? const Color(0xFF79BBF0)
              : const Color(0xFF358FBD));
    final spark = SizedBox(
      width: 46,
      height: 20,
      child: LineChart(
        values: values,
        revision: revision,
        capacity: capacity,
        minScale: 8 * 1024,
        color: color,
        fill: false,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 160 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlyphIcon(glyph, size: 12, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      height: 1.2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: display.value,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
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
                if (!stacked) ...[const SizedBox(width: 6), spark],
              ],
            ),
            if (stacked)
              Padding(padding: const EdgeInsets.only(top: 6), child: spark),
          ],
        );
      },
    );
  }
}

class _OverviewMode extends ConsumerWidget {
  const _OverviewMode();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final scheme = context.colorScheme;
    return Semantics(
      container: true,
      label: context.appLocalizations.outboundMode,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainer,
          shape: AppShape.md,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              for (final item in Mode.values)
                Expanded(
                  child: Semantics(
                    selected: item == mode,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: AppShape.all(AppCorner.md - 3),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: item == mode
                            ? scheme.surfaceContainerLow
                            : Colors.transparent,
                        foregroundColor: item == mode
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        textStyle: context.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: item == mode
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        side: item == mode
                            ? BorderSide(
                                color: scheme.outlineVariant,
                                width: 0.6,
                              )
                            : BorderSide.none,
                      ),
                      onPressed: () => ref
                          .read(setupActionProvider.notifier)
                          .changeMode(item),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
