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
      final theme = ThemeData(
        colorScheme: scheme,
      ).withAppShapes.withInterfaceTheme;
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
    Brightness brightness = Brightness.light,
    List<Group> groups = const [],
    Map<String, String> selectedMap = const {},
    String? currentGroupName,
    Mode mode = Mode.rule,
  }) async {
    final profile = Profile(
      id: 1,
      autoUpdateDuration: Duration.zero,
      selectedMap: selectedMap,
      currentGroupName: currentGroupName,
    );
    final container = ProviderContainer(
      overrides: [
        initProvider.overrideWithBuild((_, _) => true),
        profilesProvider.overrideWithValue(hasProfile ? [profile] : []),
        currentProfileProvider.overrideWithValue(hasProfile ? profile : null),
        suspendProvider.overrideWithValue(suspended),
        setupActionProvider.overrideWith(_RecordingSetupAction.new),
        groupsProvider.overrideWithBuild(
          (_, _) => [
            for (final group in groups)
              group.copyWith(hidden: group.hidden ?? false),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container.read(runTimeProvider.notifier).value = runTime;
    container
        .read(patchClashConfigProvider.notifier)
        .update((value) => value.copyWith(mode: mode));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          includeNavigatorKey: false,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Theme(
                data: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF0A59F7),
                    brightness: brightness,
                  ),
                ).withAppShapes.withInterfaceTheme,
                child: const Scaffold(
                  body: SingleChildScrollView(child: ConnectionOverview()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  for (final brightness in Brightness.values) {
    testWidgets('overview follows the $brightness surface and text roles', (
      tester,
    ) async {
      await pumpOverview(tester, runTime: 1, brightness: brightness);
      final overview = find.byType(ConnectionOverview);
      final context = tester.element(overview);
      final scheme = Theme.of(context).colorScheme;
      final panel = tester.widget<DecoratedBox>(
        find
            .descendant(of: overview, matching: find.byType(DecoratedBox))
            .first,
      );
      expect(
        (panel.decoration as ShapeDecoration).gradient,
        isA<LinearGradient>(),
      );
      final status = tester.widget<Text>(
        find.text(context.appLocalizations.connected),
      );
      expect(status.style?.color, scheme.connectionAccent);
      expect(tester.takeException(), isNull);
    });
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

  testWidgets(
    'overview resolves nested automatic groups and follows actual picks',
    (tester) async {
      const groups = [
        Group(
          name: 'Route',
          type: GroupType.Selector,
          now: 'Auto',
          all: [Proxy(name: 'Auto', type: 'URLTest')],
        ),
        Group(
          name: 'Auto',
          type: GroupType.URLTest,
          now: 'Hong Kong 01',
          all: [
            Proxy(name: 'Hong Kong 01', type: 'Trojan'),
            Proxy(name: 'Tokyo 02', type: 'VLESS'),
          ],
        ),
      ];
      final container = await pumpOverview(
        tester,
        runTime: 1,
        groups: groups,
        currentGroupName: 'Route',
        selectedMap: {'Route': 'Auto'},
      );
      expect(find.text('Hong Kong 01'), findsOneWidget);
      expect(find.text('Trojan'), findsOneWidget);
      container
          .read(groupsProvider.notifier)
          .update(
            (value) => [value.first, value.last.copyWith(now: 'Tokyo 02')],
          );
      await tester.pump();
      expect(find.text('Tokyo 02'), findsOneWidget);
      expect(find.text('Hong Kong 01'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('global mode resolves GLOBAL rather than the last rule group', (
    tester,
  ) async {
    await pumpOverview(
      tester,
      runTime: 1,
      mode: Mode.global,
      currentGroupName: 'Route',
      groups: const [
        Group(
          name: 'Route',
          type: GroupType.Selector,
          now: 'Hong Kong 01',
          all: [Proxy(name: 'Hong Kong 01', type: 'Trojan')],
        ),
        Group(
          name: 'GLOBAL',
          type: GroupType.Selector,
          now: 'Tokyo 02',
          all: [Proxy(name: 'Tokyo 02', type: 'VLESS')],
        ),
      ],
    );
    expect(find.text('Tokyo 02'), findsOneWidget);
    expect(find.text('Hong Kong 01'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct mode removes the former proxy node', (tester) async {
    await pumpOverview(
      tester,
      runTime: 1,
      mode: Mode.direct,
      groups: const [
        Group(
          name: 'Route',
          type: GroupType.Selector,
          now: 'Hong Kong 01',
          all: [Proxy(name: 'Hong Kong 01', type: 'Trojan')],
        ),
      ],
    );
    expect(find.text('Hong Kong 01'), findsNothing);
    final labels = tester
        .element(find.byType(ConnectionOverview))
        .appLocalizations;
    expect(find.text(labels.switchNode), findsNothing);
    expect(find.text(labels.direct), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stopped overview identifies its node as selected rather than active',
    (tester) async {
      await pumpOverview(
        tester,
        groups: const [
          Group(
            name: 'Route',
            type: GroupType.Selector,
            now: 'Hong Kong 01',
            all: [Proxy(name: 'Hong Kong 01', type: 'Trojan')],
          ),
        ],
      );
      final labels = tester
          .element(find.byType(ConnectionOverview))
          .appLocalizations;
      expect(find.text(labels.selectedNode), findsOneWidget);
      expect(find.text(labels.currentNode), findsNothing);
      expect(find.text('Hong Kong 01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unresolved group is not presented as a concrete node', (
    tester,
  ) async {
    await pumpOverview(
      tester,
      runTime: 1,
      groups: const [Group(name: 'Route', type: GroupType.Selector)],
    );
    final labels = tester
        .element(find.byType(ConnectionOverview))
        .appLocalizations;
    expect(find.text(labels.noInfo), findsOneWidget);
    expect(find.text(labels.switchNode), findsOneWidget);
    expect(tester.takeException(), isNull);
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
