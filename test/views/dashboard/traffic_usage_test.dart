import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widget_metrics.dart';
import 'package:fl_clash/views/dashboard/widgets/traffic_usage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required double width,
    required double unitHeight,
    double textScale = 1,
    int up = 0,
    int down = 0,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    globalState.container = container;
    container.read(totalTrafficProvider.notifier).value = Traffic(
      up: up,
      down: down,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: DashboardWidgetMetrics(
                      unitHeight: unitHeight,
                      child: const TrafficUsage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the cumulative total with upload and download breakdown', (
    tester,
  ) async {
    const up = 1024;
    const down = 2048;
    await pumpCard(tester, width: 260, unitHeight: 120, up: up, down: down);
    final total = (up + down).traffic;
    expect(
      find.text('${total.value} ${total.unit}', findRichText: true),
      findsOneWidget,
    );
    expect(find.byTooltip('Upload'), findsOneWidget);
    expect(find.byTooltip('Download'), findsOneWidget);
    expect(find.text(up.traffic.show), findsOneWidget);
    expect(find.text(down.traffic.show), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow tile keeps both directions without overflow', (
    tester,
  ) async {
    await pumpCard(tester, width: 173, unitHeight: 80);
    expect(find.byTooltip('Upload'), findsOneWidget);
    expect(find.byTooltip('Download'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow tile supports enlarged text', (tester) async {
    await pumpCard(tester, width: 173, unitHeight: 80, textScale: 1.4);
    expect(tester.takeException(), isNull);
  });
}
