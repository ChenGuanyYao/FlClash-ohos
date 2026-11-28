import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/views/dashboard/widgets/widgets.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show listEquals;

List<DashboardWidget> visibleDashboardWidgets(
  List<DashboardWidget> configured,
  SupportPlatform platform,
) {
  final visible = configured
      .where((item) => item.platforms.contains(platform))
      .toList(growable: false);
  if (platform == SupportPlatform.ohos &&
      listEquals(visible, const [
        DashboardWidget.networkSpeed,
        DashboardWidget.outboundMode,
        DashboardWidget.networkDetection,
        DashboardWidget.trafficUsage,
        DashboardWidget.intranetIp,
      ])) {
    return const [
      DashboardWidget.trafficUsage,
      DashboardWidget.profiles,
      DashboardWidget.networkDetection,
    ];
  }
  return visible;
}

extension DashboardWidgetView on DashboardWidget {
  GridItem get widget => switch (this) {
    DashboardWidget.networkSpeed => const GridItem(
      key: ValueKey(DashboardWidget.networkSpeed),
      crossAxisCellCount: 8,
      child: NetworkSpeed(),
    ),
    DashboardWidget.outboundMode => const GridItem(
      key: ValueKey(DashboardWidget.outboundMode),
      crossAxisCellCount: 4,
      child: OutboundMode(),
    ),
    DashboardWidget.trafficUsage => const GridItem(
      key: ValueKey(DashboardWidget.trafficUsage),
      crossAxisCellCount: 4,
      child: TrafficUsage(),
    ),
    DashboardWidget.networkDetection => const GridItem(
      key: ValueKey(DashboardWidget.networkDetection),
      crossAxisCellCount: 8,
      child: NetworkDetection(),
    ),
    DashboardWidget.tunButton => const GridItem(
      key: ValueKey(DashboardWidget.tunButton),
      crossAxisCellCount: 4,
      child: TUNButton(),
    ),
    DashboardWidget.vpnButton => const GridItem(
      key: ValueKey(DashboardWidget.vpnButton),
      crossAxisCellCount: 4,
      child: VpnButton(),
    ),
    DashboardWidget.systemProxyButton => const GridItem(
      key: ValueKey(DashboardWidget.systemProxyButton),
      crossAxisCellCount: 4,
      child: SystemProxyButton(),
    ),
    DashboardWidget.intranetIp => const GridItem(
      key: ValueKey(DashboardWidget.intranetIp),
      crossAxisCellCount: 4,
      child: IntranetIP(),
    ),
    DashboardWidget.memoryInfo => const GridItem(
      key: ValueKey(DashboardWidget.memoryInfo),
      crossAxisCellCount: 4,
      child: MemoryInfo(),
    ),
    DashboardWidget.serviceStatus => const GridItem(
      key: ValueKey(DashboardWidget.serviceStatus),
      crossAxisCellCount: 8,
      child: ServiceStatusCard(),
    ),
    DashboardWidget.dnsQueries => const GridItem(
      key: ValueKey(DashboardWidget.dnsQueries),
      crossAxisCellCount: 4,
      child: DnsQueriesCard(),
    ),
    DashboardWidget.requests => const GridItem(
      key: ValueKey(DashboardWidget.requests),
      crossAxisCellCount: 4,
      child: RequestsCard(),
    ),
    DashboardWidget.connections => const GridItem(
      key: ValueKey(DashboardWidget.connections),
      crossAxisCellCount: 4,
      child: ConnectionsCard(),
    ),
    DashboardWidget.overrideDnsButton => const GridItem(
      key: ValueKey(DashboardWidget.overrideDnsButton),
      crossAxisCellCount: 4,
      child: OverrideDnsButton(),
    ),
    DashboardWidget.overrideNtpButton => const GridItem(
      key: ValueKey(DashboardWidget.overrideNtpButton),
      crossAxisCellCount: 4,
      child: OverrideNtpButton(),
    ),
    DashboardWidget.runTime => const GridItem(
      key: ValueKey(DashboardWidget.runTime),
      crossAxisCellCount: 4,
      child: RunTimeCard(),
    ),
    DashboardWidget.proxyGroups => const GridItem(
      key: ValueKey(DashboardWidget.proxyGroups),
      crossAxisCellCount: 4,
      child: ProxyGroupsCard(),
    ),
    DashboardWidget.profiles => const GridItem(
      key: ValueKey(DashboardWidget.profiles),
      crossAxisCellCount: 4,
      child: ProfilesCard(),
    ),
  };
}

DashboardWidget dashboardWidgetOf(GridItem gridItem) {
  return (gridItem.key! as ValueKey<DashboardWidget>).value;
}
