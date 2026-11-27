import 'dart:math' as math;
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'tab.dart';

class ProxiesPickerView extends ConsumerStatefulWidget {
  const ProxiesPickerView({
    super.key,
    required this.title,
    this.menuItems = const [],
  });
  final String title;
  final List<CommonPopupMenuItem> menuItems;
  @override
  ConsumerState<ProxiesPickerView> createState() => _ProxiesPickerViewState();
}

class _ProxiesPickerViewState extends ConsumerState<ProxiesPickerView> {
  final _scrollController = ScrollController();
  late final _searchController = TextEditingController(
    text: ref.read(queryProvider(QueryTag.proxies)),
  );
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proxiesTabStateProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((value) => value.mode),
    );
    final groups = ref
        .watch(currentGroupsStateProvider)
        .value
        .where(
          (group) => mode == Mode.global
              ? group.name == 'GLOBAL'
              : group.name != 'GLOBAL',
        )
        .toList();
    final group =
        groups
            .where((value) => value.name == state.currentGroupName)
            .firstOrNull ??
        groups.firstOrNull;
    final visible = state.groups
        .where((value) => value.name == group?.name)
        .firstOrNull;
    final scheme = context.colorScheme;
    final labels = context.appLocalizations;
    final theme = Theme.of(context);
    final testing =
        group != null &&
        ref.watch(
          delayTestingGroupsProvider.select(
            (value) => value.contains(group.name),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 25, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: TonalButtonTheme(
                  size: TonalButtonSize.interface,
                  child: IconButton(
                    tooltip: labels.close,
                    onPressed: context.safeNestedPop,
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(34),
                      minimumSize: const Size.square(34),
                    ),
                    icon: GlyphIcon(
                      AppGlyphs.close,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CommonPopupBox(
            targetBuilder: (open) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => open(offset: Offset.zero),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  group == null
                      ? labels.proxiesEmpty
                      : '${group.name} · ${labels.nodesCountTotal(group.all.length)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            popupBuilder: (_) => CommonPopupMenu(
              items: [
                for (final item in groups)
                  CommonPopupMenuItem(
                    label: item.name,
                    checked: item.name == group?.name,
                    onPressed: () {
                      ref
                          .read(proxiesActionProvider.notifier)
                          .updateCurrentGroupName(item.name);
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0);
                      }
                    },
                  ),
                if (group != null)
                  CommonPopupMenuItem(
                    label: labels.testNodeLatency,
                    glyph: AppGlyphs.bolt,
                    onPressed: testing
                        ? null
                        : () => ref
                              .read(proxiesActionProvider.notifier)
                              .delayTestPageGroup(group.name),
                  ),
                ...widget.menuItems,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Theme(
            data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                filled: true,
                fillColor: scheme.surfaceContainer,
                border: AppShape.input.copyWith(borderRadius: AppRadius.md),
                enabledBorder: AppShape.input.copyWith(
                  borderRadius: AppRadius.md,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: AppShape.input.copyWith(
                  borderRadius: AppRadius.md,
                  borderSide: BorderSide(color: scheme.primary, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            child: SearchField(
              controller: _searchController,
              hintText: labels.searchNodeName,
              onChanged: (value) =>
                  ref.read(queryProvider(QueryTag.proxies).notifier).value =
                      value,
            ),
          ),
        ),
        Expanded(
          child: visible == null || visible.all.isEmpty
              ? Center(child: Text(labels.proxiesEmpty))
              : ProxyGroupView(
                  group: visible,
                  controller: _scrollController,
                  columns: 1,
                  cardType: state.proxyCardType,
                  picker: true,
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            math.max(16, MediaQuery.paddingOf(context).bottom),
          ),
          child: Text(
            labels.lastDelayHint,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              height: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
