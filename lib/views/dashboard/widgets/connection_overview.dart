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
    final running = ref.watch(isStartProvider);
    final suspended = running && ref.watch(suspendProvider);
    final hasProfile = ref.watch(
      profilesProvider.select((profiles) => profiles.isNotEmpty),
    );
    final profile = ref.watch(currentProfileProvider);
    final active = running && !suspended;
    final accent = active ? scheme.connectionAccent : scheme.primary;
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
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: AppShape.xxl.copyWith(
          side: BorderSide(color: scheme.outlineVariant),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLow,
            Color.alphaBlend(
              accent.withValues(alpha: 0.05),
              scheme.surfaceContainerLow,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                GlyphIcon(AppGlyphs.connections, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels.connection,
                    style: context.textTheme.titleSmall,
                  ),
                ),
                const _OverviewRuntime(),
              ],
            ),
            const SizedBox(height: 20),
            Tooltip(
              message: action,
              child: SizedBox.square(
                dimension: 144,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: AppShape.circle.copyWith(
                      side: BorderSide(color: accent.withValues(alpha: 0.18)),
                    ),
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: active ? 0.18 : 0.10),
                        accent.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: AppShape.circle,
                        padding: const EdgeInsets.all(20),
                        backgroundColor: accent,
                        foregroundColor: active
                            ? scheme.brightness == Brightness.dark
                                  ? const Color(0xFF062A20)
                                  : Colors.white
                            : scheme.onPrimary,
                      ),
                      onPressed: () {
                        if (!hasProfile) {
                          ref
                              .read(currentPageLabelProvider.notifier)
                              .toPage(PageLabel.profiles);
                          return;
                        }
                        ref.read(commonActionProvider.notifier).toggleRunning();
                      },
                      child: Semantics(
                        label: action,
                        child: GlyphIcon(
                          suspended
                              ? AppGlyphs.wifiOff
                              : AppGlyphs.playPause(running ? 1 : 0),
                          size: 40,
                          fill: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              status,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall?.copyWith(color: accent),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => ref
                  .read(currentPageLabelProvider.notifier)
                  .toPage(PageLabel.profiles),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      profile?.realLabel ?? labels.addProfile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const GlyphIcon(AppGlyphs.chevronForward, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _OverviewMode(),
            const SizedBox(height: 16),
            const _OverviewTraffic(),
          ],
        ),
      ),
    );
  }
}

class _OverviewRuntime extends ConsumerWidget {
  const _OverviewRuntime();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      getTimeText(ref.watch(runTimeProvider)),
      style: context.textTheme.labelMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _OverviewTraffic extends ConsumerWidget {
  const _OverviewTraffic();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffic = ref.watch(trafficsProvider).list.safeLast(const Traffic());
    final labels = context.appLocalizations;
    return Row(
      children: [
        Expanded(
          child: _TrafficValue(
            glyph: AppGlyphs.arrowUp,
            label: labels.upload,
            value: traffic.up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TrafficValue(
            glyph: AppGlyphs.arrowDown,
            label: labels.download,
            value: traffic.down,
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
  });

  final Glyph glyph;
  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.colorScheme.surfaceContainer,
        shape: AppShape.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlyphIcon(glyph, size: 14, color: context.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${value.traffic.show}/s',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
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
          shape: AppShape.full,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final item in Mode.values)
                Expanded(
                  child: Semantics(
                    selected: item == mode,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: item == mode
                            ? scheme.surfaceContainerLow
                            : Colors.transparent,
                        foregroundColor: item == mode
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
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
