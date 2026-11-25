import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void selectGroupProxy(
  WidgetRef ref, {
  required String groupName,
  required GroupType groupType,
  required String proxyName,
}) {
  final isComputedSelected = groupType.isComputedSelected;
  if (isComputedSelected || groupType == GroupType.Selector) {
    final currentProxyName = ref.read(proxyNameProvider(groupName));
    final nextProxyName = switch (isComputedSelected) {
      true => currentProxyName == proxyName ? '' : proxyName,
      false => proxyName,
    };
    ref
        .read(proxiesActionProvider.notifier)
        .changeProxyDebounce(groupName, nextProxyName);
    return;
  }
  dialogs.showNotifier(
    currentAppLocalizations.notSelectedTip,
    level: MessageLevel.warning,
  );
}

class ProxyCard extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
    this.compact = false,
  });

  final bool compact;

  Measure get measure => globalState.measure;

  Widget _buildProxyNameText(BuildContext context) {
    if (type == ProxyCardType.min) {
      return SizedBox(
        height: measure.bodyMediumHeight * 1,
        child: EmojiText(
          proxy.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return SizedBox(
        height: measure.bodyMediumHeight * 2,
        child: EmojiText(
          proxy.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  Widget _compactContent(BuildContext context, bool selected, Widget delay) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.07)
                : scheme.surfaceContainer,
            shape: AppShape.sm,
          ),
          child: SizedBox.square(
            dimension: 32,
            child: Center(
              child: GlyphIcon(
                selected ? AppGlyphs.checkCircle : AppGlyphs.proxies,
                size: 17,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiText(
                proxy.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (type != ProxyCardType.min) ...[
                const SizedBox(height: 4),
                if (type == ProxyCardType.expand)
                  _ProxyDesc(proxy: proxy)
                else
                  Text(
                    proxy.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        delay,
        if (groupType.isComputedSelected) const SizedBox(width: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measure = globalState.measure;
    final selected =
        ref.watch(selectedProxyNameProvider(groupName)) == proxy.name;
    final delayText = _DelayText(proxy: proxy, testUrl: testUrl, type: type);
    return Stack(
      children: [
        CommonCard(
          radius: AppCorner.md,
          enterActionsOnRight: true,
          isSelected: selected,
          onPressed: () {
            selectGroupProxy(
              ref,
              groupName: groupName,
              groupType: groupType,
              proxyName: proxy.name,
            );
          },
          child: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: compact
                ? _compactContent(context, selected, delayText)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: GlyphIcon(
                              selected
                                  ? AppGlyphs.checkCircle
                                  : AppGlyphs.proxies,
                              size: 16,
                              color: selected
                                  ? context.colorScheme.primary
                                  : context.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: _buildProxyNameText(context)),
                          if (groupType.isComputedSelected)
                            const SizedBox(width: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (type == ProxyCardType.expand) ...[
                        SizedBox(
                          height: measure.bodySmallHeight,
                          child: _ProxyDesc(proxy: proxy),
                        ),
                        const SizedBox(height: 6),
                        delayText,
                      ] else
                        SizedBox(
                          height: measure.bodySmallHeight,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  proxy.type,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              delayText,
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (groupType.isComputedSelected)
          Positioned(
            top: 0,
            right: 0,
            child: _ProxyComputedMark(groupName: groupName, proxy: proxy),
          ),
      ],
    );
  }
}

class _DelayText extends ConsumerStatefulWidget {
  const _DelayText({
    required this.proxy,
    required this.testUrl,
    required this.type,
  });

  final Proxy proxy;
  final String? testUrl;
  final ProxyCardType type;

  @override
  ConsumerState<_DelayText> createState() => _DelayTextState();
}

class _DelayTextState extends ConsumerState<_DelayText> {
  final FocusNode _focusNode = SkipTraversalFocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final isFocused = _focusNode.hasPrimaryFocus;
    if (isFocused == _isFocused) {
      return;
    }
    setState(() {
      _isFocused = isFocused;
    });
  }

  void _handleTestCurrentDelay() {
    ref
        .read(proxiesActionProvider.notifier)
        .proxyDelayTest(widget.proxy, widget.testUrl);
  }

  Widget _withFocusRing(BuildContext context, Widget child) {
    if (!_isFocused) {
      return child;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -3,
          bottom: -2,
          left: -3,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: AppRadius.xs,
                  side: BorderSide(
                    color: context.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final measure = globalState.measure;
    final delay = ref.watch(
      delayProvider(proxyName: widget.proxy.name, testUrl: widget.testUrl),
    );
    final phase = ref.watch(
      delayTestPhaseProvider(
        proxyName: widget.proxy.name,
        testUrl: widget.testUrl,
      ),
    );
    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleTestCurrentDelay();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _focusNode,
        child: SizedBox(
          height: measure.labelSmallHeight,
          child: FadeBox(
            alignment: widget.type == ProxyCardType.expand
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: phase != null || delay == null
                ? SizedBox(
                    height: measure.labelSmallHeight,
                    width: measure.labelSmallHeight,
                    child: _withFocusRing(context, switch (phase) {
                      DelayTestPhase.running => const CommonCircleLoading(),
                      DelayTestPhase.queued => GlyphIcon(
                        AppGlyphs.clock,
                        size: measure.labelSmallHeight,
                        color: context.colorScheme.onSurfaceVariant.opacity38,
                      ),
                      null => IconButton(
                        tooltip: context.appLocalizations.delayTest,
                        icon: const GlyphIcon(AppGlyphs.bolt),
                        iconSize: measure.labelSmallHeight,
                        padding: EdgeInsets.zero,
                        onPressed: _handleTestCurrentDelay,
                      ),
                    }),
                  )
                : GestureDetector(
                    onTap: _handleTestCurrentDelay,
                    child: _withFocusRing(
                      context,
                      Text(
                        delay > 0 ? '$delay ms' : 'Timeout',
                        maxLines: 1,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          overflow: TextOverflow.ellipsis,
                          color: Color.alphaBlend(
                            context.colorScheme.onSurface.withValues(
                              alpha:
                                  Theme.brightnessOf(context) ==
                                      Brightness.light
                                  ? 0.32
                                  : 0.04,
                            ),
                            context.colorScheme.delayColor(delay) ??
                                context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProxyDesc extends ConsumerWidget {
  final Proxy proxy;

  const _ProxyDesc({required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desc = ref.watch(proxyDescProvider(proxy));
    return EmojiText(
      desc,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textTheme.bodySmall?.color?.opacity80,
      ),
    );
  }
}

class _ProxyComputedMark extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;

  const _ProxyComputedMark({required this.groupName, required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref.watch(proxyNameProvider(groupName));
    if (proxyName != proxy.name) {
      return const SizedBox();
    }
    return Container(
      alignment: Alignment.topRight,
      margin: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: const SelectIcon(),
      ),
    );
  }
}
