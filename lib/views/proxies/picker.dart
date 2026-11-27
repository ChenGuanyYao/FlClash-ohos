import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'tab.dart';

class ProxiesPickerView extends ConsumerStatefulWidget {
  const ProxiesPickerView({super.key});
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
    final currentName = ref.watch(
      currentProfileProvider.select((value) => value?.currentGroupName),
    );
    final group =
        groups.where((value) => value.name == currentName).firstOrNull ??
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
    return AppBarClearance(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    tooltip: labels.proxyGroup,
                    onSelected: (name) {
                      ref
                          .read(proxiesActionProvider.notifier)
                          .updateCurrentGroupName(name);
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0);
                      }
                    },
                    itemBuilder: (_) => [
                      for (final item in groups)
                        PopupMenuItem(value: item.name, child: Text(item.name)),
                    ],
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            group == null
                                ? labels.proxiesEmpty
                                : '${group.name} · ${labels.nodesCount(group.all.length)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GlyphIcon(
                          AppGlyphs.chevronDown,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: group == null || testing
                      ? null
                      : () => ref
                            .read(proxiesActionProvider.notifier)
                            .delayTestPageGroup(group.name),
                  child: Text(
                    labels.delayTest,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Theme(
              data: theme.copyWith(
                inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: AppShape.input.copyWith(borderRadius: AppRadius.md),
                  enabledBorder: AppShape.input.copyWith(
                    borderRadius: AppRadius.md,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              child: SearchField(
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(queryProvider(QueryTag.proxies).notifier).value =
                        value,
              ),
            ),
          ),
          Expanded(
            child: visible == null || visible.all.isEmpty
                ? Center(
                    child: Text(
                      labels.proxiesEmpty,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ProxyGroupView(
                    group: visible,
                    controller: _scrollController,
                    columns: 1,
                    cardType: state.proxyCardType,
                    picker: true,
                  ),
          ),
        ],
      ),
    );
  }
}
