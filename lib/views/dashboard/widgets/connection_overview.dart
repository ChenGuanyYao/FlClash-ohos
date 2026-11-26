import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionOverview extends ConsumerWidget {
  const ConnectionOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final labels = context.appLocalizations;
    final dark = scheme.brightness == Brightness.dark;
    final running = ref.watch(isStartProvider);
    final suspended = running && ref.watch(suspendProvider);
    final hasProfile = ref.watch(
      profilesProvider.select((value) => value.isNotEmpty),
    );
    final profile = ref.watch(currentProfileProvider);
    final active = running && !suspended;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: scheme.surfaceContainerLow,
            shape: AppShape.xl.copyWith(
              side: BorderSide(color: scheme.outlineVariant, width: 0.7),
            ),
            shadows: dark
                ? const []
                : [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.035),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 6),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        labels.connection,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const _OverviewRuntime(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Tooltip(
                      message: action,
                      excludeFromSemantics: true,
                      child: SizedBox.square(
                        dimension: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: AppShape.md,
                            padding: EdgeInsets.zero,
                            backgroundColor: active
                                ? scheme.primary
                                : scheme.surfaceContainerHigh,
                            foregroundColor: active
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                            side: BorderSide(
                              color: active
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              width: 0.8,
                            ),
                            elevation: 0,
                          ),
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
                          child: Semantics(
                            label: action,
                            child: GlyphIcon(
                              suspended ? AppGlyphs.wifiOff : AppGlyphs.power,
                              size: 25,
                              fill: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  thickness: 0.6,
                  color: scheme.outlineVariant,
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: AppShape.sm,
                    onTap: () => ref
                        .read(currentPageLabelProvider.notifier)
                        .toPage(PageLabel.profiles),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          GlyphIcon(
                            AppGlyphs.profiles,
                            size: 15,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              profile?.realLabel ?? labels.addProfile,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          GlyphIcon(
                            AppGlyphs.chevronForward,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _OverviewMode(),
        const SizedBox(height: 16),
        const _OverviewTraffic(),
      ],
    );
  }
}

class _OverviewRuntime extends ConsumerWidget {
  const _OverviewRuntime();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
    getTimeText(ref.watch(runTimeProvider)),
    style: context.textTheme.labelMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontSize: 11,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

class _OverviewTraffic extends ConsumerWidget {
  const _OverviewTraffic();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffic = ref.watch(trafficsProvider).list.safeLast(const Traffic());
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerLow,
        shape: AppShape.lg.copyWith(
          side: BorderSide(color: scheme.outlineVariant, width: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: _TrafficValue(
                glyph: AppGlyphs.arrowUp,
                label: context.appLocalizations.upload,
                value: traffic.up,
              ),
            ),
            SizedBox(
              height: 42,
              child: VerticalDivider(
                width: 28,
                thickness: 0.6,
                color: scheme.outlineVariant,
              ),
            ),
            Expanded(
              child: _TrafficValue(
                glyph: AppGlyphs.arrowDown,
                label: context.appLocalizations.download,
                value: traffic.down,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficValue extends StatelessWidget {
  const _TrafficValue({
    required this.glyph,
    required this.label,
    required this.value,
  });
  final Glyph glyph;
  final String label;
  final num value;
  @override
  Widget build(BuildContext context) {
    final display = value.traffic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GlyphIcon(
              glyph,
              size: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
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
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.8,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: ' ${display.unit}/s',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
