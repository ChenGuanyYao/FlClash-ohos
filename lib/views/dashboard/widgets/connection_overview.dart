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
    final visible = groups
        .where(
          (group) => mode == Mode.global
              ? group.name == GroupName.GLOBAL.name
              : mode != Mode.direct &&
                    group.hidden == false &&
                    group.name != GroupName.GLOBAL.name,
        )
        .toList();
    final preferred = ref.watch(currentGroupNameProvider);
    final group =
        visible.where((item) => item.name == preferred).firstOrNull ??
        visible.firstOrNull;
    final resolved = group == null
        ? null
        : ref.watch(realSelectedProxyStateProvider(group.name));
    final nodeName = resolved?.proxyName;
    final node = groups
        .expand((item) => item.all)
        .where((item) => item.name == nodeName)
        .firstOrNull;
    final unresolved =
        nodeName == null ||
        nodeName.isEmpty ||
        groups.any((item) => item.name == nodeName);
    final title = !hasProfile
        ? labels.addProfile
        : mode == Mode.direct
        ? labels.direct
        : unresolved
        ? labels.noInfo
        : nodeName ?? labels.noInfo;
    final status = suspended
        ? labels.suspended
        : running
        ? labels.connected
        : labels.disconnected;
    final action = !hasProfile
        ? labels.addProfile
        : running
        ? labels.stop
        : labels.start;
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
        props: const SheetProps(isScrollControlled: true),
        builder: (_) => const ProxiesView(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: () => ref
                .read(currentPageLabelProvider.notifier)
                .toPage(PageLabel.profiles),
            icon: const GlyphIcon(AppGlyphs.profiles, size: 14),
            label: Text(
              profile?.realLabel ?? labels.addProfile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: ShapeDecoration(
            gradient: scheme.interfaceGradient(raised: true),
            shape: AppShape.xl.copyWith(
              side: BorderSide(color: scheme.outlineVariant, width: 0.65),
            ),
            shadows: scheme.interfaceShadows(raised: true),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        ),
                      ),
                    ),
                    if (group != null)
                      Flexible(
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
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
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active ? labels.currentNode : labels.selectedNode,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 7,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (group != null &&
                                  !unresolved &&
                                  active &&
                                  mode != Mode.direct)
                                _OverviewDelay(
                                  groupName: group.name,
                                  testUrl: group.testUrl,
                                ),
                              if (node != null &&
                                  !unresolved &&
                                  mode != Mode.direct)
                                Text(
                                  node.type,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              const _OverviewRuntime(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _OverviewPower(
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
                        ref.read(commonActionProvider.notifier).toggleRunning();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    onPressed: mode == Mode.direct
                        ? () => ref
                              .read(currentPageLabelProvider.notifier)
                              .toPage(PageLabel.connections)
                        : switchNode,
                    icon: GlyphIcon(
                      mode == Mode.direct
                          ? AppGlyphs.connections
                          : AppGlyphs.proxies,
                      size: 15,
                    ),
                    label: Text(
                      !hasProfile
                          ? labels.addProfile
                          : mode == Mode.direct
                          ? labels.connections
                          : labels.switchNode,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant,
                  thickness: 0.6,
                ),
                const SizedBox(height: 18),
                const _OverviewTraffic(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
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
              padding: const EdgeInsets.all(3),
              child: FilledButton(
                style:
                    FilledButton.styleFrom(
                      minimumSize: const Size.square(68),
                      maximumSize: const Size.square(68),
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
                              gradient: scheme.interfaceGradient(
                                color: running
                                    ? scheme.surfaceContainerLow
                                    : scheme.primary,
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
                  child: GlyphIcon(glyph, size: 26, fill: 1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
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
  final String testUrl;
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
            label: context.appLocalizations.upload,
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
            label: context.appLocalizations.download,
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
        ? scheme.suspendedAccent
        : scheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GlyphIcon(glyph, size: 12, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: display.value,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: ' ${display.unit}/s',
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 16,
          child: LineChart(
            values: values,
            revision: revision,
            capacity: capacity,
            minScale: 8 * 1024,
            color: color,
          ),
        ),
      ],
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
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: item == mode
                            ? scheme.surfaceContainerLow
                            : Colors.transparent,
                        foregroundColor: item == mode
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        textStyle: context.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: item == mode
                              ? FontWeight.w600
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
