import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
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
      height: DashboardWidgetMetrics.heightOf(context, 1.65, textHeight: 96),
      child: RepaintBoundary(
        child: CommonCard(
          radius: DashboardWidgetMetrics.radiusOf(context),
          infoPadding: DashboardWidgetMetrics.paddingOf(
            context,
          ).copyWith(top: 16, bottom: 10),
          infoTextStyle: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
          info: Info(label: context.appLocalizations.totalTraffic),
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
      padding: DashboardWidgetMetrics.paddingOf(context).copyWith(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: total.value,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: 27,
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
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _TrafficDataItem(glyph: AppGlyphs.arrowUp, value: up),
              _TrafficDataItem(glyph: AppGlyphs.arrowDown, value: down),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.appLocalizations.currentSession,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficDataItem extends StatelessWidget {
  const _TrafficDataItem({required this.glyph, required this.value});
  final Glyph glyph;
  final num value;
  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    return Tooltip(
      message: glyph == AppGlyphs.arrowUp
          ? context.appLocalizations.upload
          : context.appLocalizations.download,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlyphIcon(
            glyph,
            size: 12,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),

          Text(
            value.traffic.show,
            style: style?.copyWith(
              color: context.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
