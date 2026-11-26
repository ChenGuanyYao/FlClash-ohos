import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/views/dashboard/widget_metrics.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrafficUsage extends StatelessWidget {
  const TrafficUsage({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DashboardWidgetMetrics.heightOf(context, 2),
      child: RepaintBoundary(
        child: CommonCard(
          radius: DashboardWidgetMetrics.radiusOf(context),
          infoPadding: DashboardWidgetMetrics.paddingOf(
            context,
          ).copyWith(bottom: 0),
          info: Info(
            label: context.appLocalizations.trafficUsage,
            glyph: AppGlyphs.dataUsage,
          ),
          child: Consumer(
            builder: (_, ref, _) {
              final traffic = ref.watch(totalTrafficProvider);
              return _TrafficUsageBody(up: traffic.up, down: traffic.down);
            },
          ),
        ),
      ),
    );
  }
}

class _TrafficUsageBody extends StatelessWidget {
  const _TrafficUsageBody({required this.up, required this.down});
  final num up;
  final num down;
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final total = (up + down).traffic;
    return Padding(
      padding: DashboardWidgetMetrics.paddingOf(context).copyWith(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.appLocalizations.total,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: total.value,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' ${total.unit}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          _TrafficDataItem(
            glyph: AppGlyphs.arrowUp,
            label: context.appLocalizations.upload,
            value: up,
          ),
          const SizedBox(height: 8),
          _TrafficDataItem(
            glyph: AppGlyphs.arrowDown,
            label: context.appLocalizations.download,
            value: down,
          ),
        ],
      ),
    );
  }
}

class _TrafficDataItem extends StatelessWidget {
  const _TrafficDataItem({
    required this.glyph,
    required this.label,
    required this.value,
  });
  final Glyph glyph;
  final String label;
  final num value;
  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        GlyphIcon(glyph, size: 12, color: context.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.traffic.show,
          style: style?.copyWith(
            color: context.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
