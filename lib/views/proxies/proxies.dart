import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:fl_clash/views/proxies/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key, this.title});

  final String? title;

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();
  bool _hasProviders = false;

  List<CommonPopupMenuItem> _buildMenuItems(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      CommonPopupMenuItem(
        glyph: AppGlyphs.sliders,
        label: appLocalizations.settings,
        onPressed: () {
          showSheet(
            context: context,
            props: const SheetProps(isScrollControlled: true),
            builder: (_) {
              return CommonScaffold(
                body: const ProxiesSetting(),
                title: appLocalizations.settings,
              );
            },
          );
        },
      ),
      if (_hasProviders)
        CommonPopupMenuItem(
          glyph: AppGlyphs.layers,
          label: appLocalizations.providers,
          onPressed: () {
            showExtend(
              context,
              builder: (_) {
                return const ProvidersView();
              },
            );
          },
        ),
    ];
  }

  IconButtonData? _buildPrimaryAction(bool isTab) {
    if (!isTab || context.isMobileView) {
      return null;
    }
    final currentGroupName = ref.watch(
      proxiesTabControllerStateProvider.select(
        (state) => state.currentGroupName,
      ),
    );
    final isDelayTesting = ref.watch(
      delayTestingGroupsProvider.select(
        (state) => state.contains(currentGroupName),
      ),
    );
    return IconButtonData(
      glyph: AppGlyphs.bolt,
      onPressed: () {
        _proxiesTabKey.currentState?.delayTestCurrentGroup();
      },
      tooltip: context.appLocalizations.delayTest,
      isLoading: isDelayTesting,
    );
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(providersProvider.select((state) => state.isNotEmpty), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() {
          _hasProviders = next;
        });
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.type),
    );
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    final isTab = context.isMobileView || proxiesType == ProxiesType.tab;
    return CommonScaffold(
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      primaryAction: _buildPrimaryAction(isTab),
      iconActions: [
        if (isTab && !context.isMobileView)
          IconButtonData(
            glyph: AppGlyphs.locate,
            onPressed: () {
              _proxiesTabKey.currentState?.scrollToGroupSelected();
            },
            tooltip: context.appLocalizations.scrollToSelected,
          ),
      ],
      menuItems: _buildMenuItems(context),
      title: widget.title ?? context.appLocalizations.nodes,
      titleWidget: widget.title == null
          ? ProfilePageTitle(title: context.appLocalizations.nodes)
          : null,
      dockSearchInSheet: false,
      searchState: AppBarSearchState(onSearch: _onSearch),
      body: isTab
          ? ProxiesTabView(key: _proxiesTabKey)
          : const ProxiesListView(),
    );
  }
}
