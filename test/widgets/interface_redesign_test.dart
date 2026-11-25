import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/connection_overview.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';

void main() {
  test(
    'interface theme preserves the configured accent and pure-black setting',
    () {
      const accent = Color(0xFF7541C8);
      final scheme = ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ).copyWith(surface: Colors.black);
      final theme = ThemeData(colorScheme: scheme)
          .withAppShapes
          .withInterfaceTheme;
      expect(theme.colorScheme.primary, scheme.primary);
      expect(theme.colorScheme.surface, Colors.black);
      expect(theme.scaffoldBackgroundColor, Colors.black);
    },
  );

  Future<ProviderContainer> pumpOverview(
    WidgetTester tester, {
    bool hasProfile = true,
    bool suspended = false,
    int? runTime,
    double textScale = 1,
  }) async {
    const profile = Profile(id: 1, autoUpdateDuration: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        profilesProvider.overrideWithValue(hasProfile ? [profile] : []),
        currentProfileProvider.overrideWithValue(hasProfile ? profile : null),
        suspendProvider.overrideWithValue(suspended),
        setupActionProvider.overrideWith(_RecordingSetupAction.new),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container.read(runTimeProvider.notifier).value = runTime;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          includeNavigatorKey: false,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: const Scaffold(
                body: SingleChildScrollView(child: ConnectionOverview()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('overview uses the existing shared start and stop action', (
    tester,
  ) async {
    final container = await pumpOverview(tester, runTime: 1);
    final action =
        container.read(setupActionProvider.notifier) as _RecordingSetupAction;
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(action.requests, [false]);
    expect(container.read(isStartProvider), isFalse);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(action.requests, [false, true]);
    expect(container.read(isStartProvider), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty profile action opens profiles without starting the core', (
    tester,
  ) async {
    final container = await pumpOverview(tester, hasProfile: false);
    await tester.tap(find.byType(FilledButton));
    expect(container.read(currentPageLabelProvider), PageLabel.profiles);
    final action =
        container.read(setupActionProvider.notifier) as _RecordingSetupAction;
    expect(action.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suspended state stays distinct from a connected tunnel', (
    tester,
  ) async {
    await pumpOverview(tester, runTime: 1, suspended: true);
    final labels = tester
        .element(find.byType(ConnectionOverview))
        .appLocalizations;
    expect(find.text(labels.suspended), findsOneWidget);
    expect(find.byGlyph(AppGlyphs.wifiOff), findsOneWidget);
    expect(find.text(labels.connected), findsNothing);
  });

  testWidgets('overview fits a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpOverview(tester, textScale: 1.4);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingSetupAction extends SetupAction {
  final requests = <bool>[];

  @override
  Future<bool> setRunning(bool running, {bool initialize = false}) {
    requests.add(running);
    ref.read(runTimeProvider.notifier).value = running ? 1 : null;
    return Future.value(true);
  }
}
