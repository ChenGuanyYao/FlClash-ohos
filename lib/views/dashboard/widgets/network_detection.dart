import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/service_probe.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/outbound_ip.dart';
import 'package:fl_clash/providers/routed_probe.dart';
import 'package:fl_clash/views/dashboard/probe_start_hold.dart';
import 'package:fl_clash/views/dashboard/widget_metrics.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkDetection extends ConsumerStatefulWidget {
  const NetworkDetection({super.key});

  @override
  ConsumerState<NetworkDetection> createState() => _NetworkDetectionState();
}

class _NetworkDetectionState extends ConsumerState<NetworkDetection>
    with ProbeStartHold<NetworkDetection> {
  late final OutboundIpProbe _probe;

  @override
  void initState() {
    super.initState();
    _probe = ref.read(outboundIpProbeProvider.notifier)..watch(routedOutbound);
  }

  @override
  void dispose() {
    _probe.unwatch(routedOutbound);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final entry = ref.watch(
      outboundIpProbeProvider.select((state) => state.entryOf(routedOutbound)),
    );
    final ipInfo = entry.value;
    final failed = shownPhase(entry) == ProbePhase.failed;
    final scheme = context.colorScheme;
    final probing = shownPhase(entry) == ProbePhase.probing;
    return SizedBox(
      height: DashboardWidgetMetrics.heightOf(context, 1, textHeight: 40) - 12,
      child: CommonCard(
        radius: AppCorner.lg,
        onPressed: probing ? null : () => _probe.retry(routedOutbound),
        onLongPress: () => dialogs.showMessage(
          title: appLocalizations.tip,
          message: TextSpan(text: appLocalizations.detectionTip),
          cancelable: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  gradient: scheme.interfaceGradient(
                    color: scheme.primary.withValues(alpha: 0.06),
                  ),
                  shape: AppShape.sm,
                ),
                child: SizedBox.square(
                  dimension: 34,
                  child: const Center(child: InterfaceGlobe(size: 20)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.networkDetection,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (ipInfo != null)
                      IpQualityText(
                        ip: ipInfo.ip,
                        openDetails: true,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        failed
                            ? appLocalizations.timeout
                            : appLocalizations.networkCheckSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: failed
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: probing ? null : () => _probe.retry(routedOutbound),
                child: probing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CommonCircleLoading(),
                      )
                    : Text(
                        appLocalizations.runNetworkCheck,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
              ),
              GlyphIcon(
                AppGlyphs.chevronForward,
                size: 12,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
