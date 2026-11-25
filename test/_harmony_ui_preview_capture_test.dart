import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/home.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/dashboard.dart';
import 'package:fl_clash/views/proxies/proxies.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/views.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const testUrl = 'https://example.com/generate_204';
final fontRoot = Platform.environment['PREVIEW_FONT_DIR'] ?? '/Users/chenguangyao/Documents/DeepSeek/.toolchains/preview-fonts';
final outputRoot = Platform.environment['PREVIEW_OUTPUT_DIR'] ?? '/Users/chenguangyao/Documents/DeepSeek/ui-reference/previews';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('HarmonyOS Sans SC');
    for (final weight in ['Regular', 'Bold']) {
      final bytes = await File('$fontRoot/HarmonyOS_Sans_SC_$weight.ttf').readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });
  final cases = [
    ('home-light', PageLabel.dashboard, Brightness.light, const Size(390, 844)),
    ('nodes-light', PageLabel.proxies, Brightness.light, const Size(390, 844)),
    ('connections-light', PageLabel.connections, Brightness.light, const Size(390, 844)),
    ('home-dark', PageLabel.dashboard, Brightness.dark, const Size(390, 844)),
    ('nodes-dark', PageLabel.proxies, Brightness.dark, const Size(390, 844)),
    ('connections-dark', PageLabel.connections, Brightness.dark, const Size(390, 844)),
    ('tablet-home-light', PageLabel.dashboard, Brightness.light, const Size(900, 1180)),
  ];
  for (final (name, page, brightness, size) in cases) {
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.ohos;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const nodes = [
        Proxy(name: '香港 01 · 低延迟', type: 'Shadowsocks'),
        Proxy(name: '香港 02 · 流媒体', type: 'Trojan'),
        Proxy(name: '日本 01 · 东京', type: 'VLESS'),
        Proxy(name: '新加坡 01', type: 'Hysteria2'),
        Proxy(name: '美国 01 · 洛杉矶', type: 'TUIC'),
        Proxy(name: '台湾 01 · 台北', type: 'Shadowsocks'),
      ];
      const groups = [
        Group(name: '节点选择', type: GroupType.Selector, all: nodes, now: '香港 01 · 低延迟', testUrl: testUrl),
        Group(name: '自动选择', type: GroupType.URLTest, all: nodes, now: '香港 01 · 低延迟', testUrl: testUrl),
      ];
      const profile = Profile(
        id: 1, label: '日常订阅', autoUpdateDuration: Duration.zero, autoUpdate: false,
        currentGroupName: '节点选择', selectedMap: {'节点选择': '香港 01 · 低延迟'},
        unfoldSet: {'节点选择'},
        subscriptionInfo: SubscriptionInfo(upload: 402653184, download: 6871947673, total: 214748364800),
      );
      final trackers = [
        ('developer.huawei.com', 'tcp', '203.0.113.10', 142336, 1887436),
        ('api.github.com', 'tcp', '203.0.113.11', 4096, 24576),
        ('www.bilibili.com', 'tcp', '203.0.113.12', 18432, 884736),
        ('dns.example.net', 'udp', '203.0.113.13', 512, 2048),
      ].indexed.map((entry) {
        final (host, network, ip, up, down) = entry.$2;
        return TrackerInfo(
          id: '${entry.$1}', start: DateTime.now().subtract(Duration(seconds: 24 + entry.$1 * 19)),
          metadata: Metadata(network: network, host: host, sourceIP: '172.19.0.1', sourcePort: '${48520 + entry.$1}', destinationIP: ip, destinationPort: '443'),
          chains: const ['香港 01 · 低延迟', '节点选择'], rule: 'DOMAIN-SUFFIX', rulePayload: host,
          upload: up * 12, download: down * 12, uploadSpeed: up, downloadSpeed: down,
        );
      }).toList();
      final container = ProviderContainer(overrides: [
        profilesProvider.overrideWithValue([profile]),
        currentProfileProvider.overrideWithValue(profile),
        suspendProvider.overrideWithValue(false),
        coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
        groupsProvider.overrideWithBuild((_, _) => groups),
        dashboardStateProvider.overrideWithValue(const DashboardState(dashboardWidgets: [DashboardWidget.trafficUsage, DashboardWidget.profiles])),
        proxiesStyleSettingProvider.overrideWithBuild((_, _) => const ProxiesStyleProps(type: ProxiesType.list, cardType: ProxyCardType.shrink)),
        delayDataSourceProvider.overrideWithBuild((_, _) => {testUrl: {
          '香港 01 · 低延迟': 28, '香港 02 · 流媒体': 36, '日本 01 · 东京': 65, '新加坡 01': 78, '美国 01 · 洛杉矶': 154, '台湾 01 · 台北': 42,
        }}),
        navigationItemsStateProvider.overrideWithValue(NavigationItemsState(value: [
          NavigationItem(glyph: AppGlyphs.dashboard, label: PageLabel.dashboard, builder: (_) => const DashboardView()),
          NavigationItem(glyph: AppGlyphs.proxies, label: PageLabel.proxies, builder: (_) => const ProxiesView()),
          NavigationItem(glyph: AppGlyphs.profiles, label: PageLabel.profiles, builder: (_) => const ProfilesView()),
          NavigationItem(glyph: AppGlyphs.connections, label: PageLabel.connections, builder: (_) => ConnectionsView(connectionsReader: () async => trackers)),
          NavigationItem(glyph: AppGlyphs.tools, label: PageLabel.tools, builder: (_) => const ToolsView()),
        ])),
      ]);
      globalState.container = container;
      container.read(viewSizeProvider.notifier).value = size;
      container.read(currentPageLabelProvider.notifier).toPage(page);
      container.read(runTimeProvider.notifier).value = 3842;
      container.read(totalTrafficProvider.notifier).value = const Traffic(up: 402653184, down: 6871947673);
      for (var i = 0; i < 32; i++) {
        container.read(trafficsProvider.notifier).addTraffic(Traffic(up: 18000 + (i % 7) * 5100, down: 650000 + (i % 9) * 155000));
      }
      final scheme = ColorScheme.fromSeed(seedColor: const Color(defaultPrimaryColor), brightness: brightness);
      final theme = ThemeData(colorScheme: scheme, fontFamily: 'HarmonyOS Sans SC', platform: TargetPlatform.ohos).withAppShapes.withInterfaceTheme;
      final key = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          theme: theme,
          builder: (context, child) {
            globalState.measure = Measure.of(context, 1);
            globalState.theme = CommonTheme.of(context, 1);
            return MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!);
          },
          home: RepaintBoundary(key: key, child: const HomePage()),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(outputRoot).createSync(recursive: true);
        await File('$outputRoot/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
    });
  }
}
