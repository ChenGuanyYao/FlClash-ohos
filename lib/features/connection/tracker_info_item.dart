import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _ruleText(TrackerInfo trackerInfo) {
  final rule = trackerInfo.rule;
  final rulePayload = trackerInfo.rulePayload;
  if (rulePayload.isNotEmpty) {
    return '$rule($rulePayload)';
  }
  return rule;
}

String _endpointText(String ip, String port) {
  if (ip.isEmpty) {
    return '';
  }
  if (port.isNotEmpty) {
    return '$ip:$port';
  }
  return ip;
}

class TrackerInfoItem extends ConsumerWidget {
  final TrackerInfo trackerInfo;
  final bool isLive;
  final Function(String)? onClickKeyword;
  final Widget? action;
  final String detailTitle;

  const TrackerInfoItem({
    super.key,
    required this.trackerInfo,
    this.isLive = false,
    this.onClickKeyword,
    this.action,
    required this.detailTitle,
  });

  @override
  Widget build(BuildContext context, ref) {
    final showIcon = ref.watch(
      patchClashConfigProvider.select(
        (state) =>
            state.findProcessMode == FindProcessMode.always && system.isAndroid,
      ),
    );
    final item = RecordListItem(
      onTap: () {
        showExtend(
          context,
          builder: (_) {
            return CommonScaffold(
              body: TrackerInfoDetailView(trackerInfo: trackerInfo),
              title: detailTitle,
            );
          },
        );
      },
      header: _buildHeader(context),
      body: _buildBody(showIcon: showIcon),
    );
    if (!isLive) {
      return item;
    }
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: scheme.interfaceGradient(),
          shape: AppShape.lg.copyWith(
            side: BorderSide(color: scheme.outlineVariant, width: 0.6),
          ),
          shadows: scheme.interfaceShadows(),
        ),
        child: Material(
          color: Colors.transparent,
          shape: AppShape.lg,
          clipBehavior: Clip.antiAlias,
          child: item,
        ),
      ),
    );
  }

  Widget _buildBody({required bool showIcon}) {
    final process = trackerInfo.metadata.process;
    final body = _TrackerInfoBody(
      trackerInfo: trackerInfo,
      onClickKeyword: onClickKeyword,
      compact: isLive,
    );
    if (!showIcon || process.isEmpty) {
      return body;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        GestureDetector(
          onTap: () => onClickKeyword?.call(process),
          child: PackageIcon(packageName: process, size: 40),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final network = DecoratedBox(
      decoration: ShapeDecoration(
        shape: AppShape.sm,
        color: context.colorScheme.surfaceContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          trackerInfo.metadata.network.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    if (!isLive) {
      return RecordHeader(
        trailing: action,
        children: [RecordTimestamp(trackerInfo.start.showFull), network],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            trackerInfo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        network,
        ?action,
      ],
    );
  }
}

class _TrackerInfoBody extends StatelessWidget {
  final TrackerInfo trackerInfo;
  final Function(String)? onClickKeyword;

  const _TrackerInfoBody({
    required this.trackerInfo,
    this.onClickKeyword,
    this.compact = false,
  });

  final bool compact;

  Widget _compactBody(BuildContext context) {
    final scheme = context.colorScheme;
    final route = trackerInfo.chains.isEmpty
        ? trackerInfo.rule
        : trackerInfo.chains.first;
    final style = context.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget rate(Glyph glyph, int value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlyphIcon(glyph, size: 11, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '${value.traffic.show}/s',
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GlyphIcon(
              AppGlyphs.proxies,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => onClickKeyword?.call(route),
                child: Text(
                  route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trackerInfo.start.getLastUpdateTimeDesc(context),
              style: style?.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            rate(AppGlyphs.arrowUp, trackerInfo.uploadSpeed ?? 0),
            const SizedBox(width: 14),
            rate(AppGlyphs.arrowDown, trackerInfo.downloadSpeed ?? 0),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                trackerInfo.metadata.destinationIP,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _compactBody(context);
    final colorScheme = context.colorScheme;
    final styles = RecordTextStyles.of(context);
    final metadata = trackerInfo.metadata;
    final rule = _ruleText(trackerInfo);
    final source = [
      trackerInfo.progressText,
      _endpointText(metadata.sourceIP, metadata.sourcePort),
    ].where((text) => text.isNotEmpty).join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _endpointText(
                  trackerInfo.title,
                  metadata.destinationPort,
                ),
                style: styles.primary?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (metadata.host.isNotEmpty && metadata.destinationIP.isNotEmpty)
                TextSpan(
                  text: '  ${metadata.destinationIP}',
                  style: styles.muted,
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (rule.isNotEmpty) Text(rule, style: styles.secondary),
            for (final (index, chain) in trackerInfo.chains.reversed.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (index > 0 || rule.isNotEmpty) const RecordArrow(),
                  Flexible(
                    child: TonalChip(
                      label: chain,
                      color: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      onPressed: () => onClickKeyword?.call(chain),
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (source.isNotEmpty) Text(source, style: styles.muted),
      ],
    );
  }
}

class TrackerInfoDetailView extends StatelessWidget {
  final TrackerInfo trackerInfo;

  const TrackerInfoDetailView({super.key, required this.trackerInfo});

  Widget _buildChains(BuildContext context) {
    return DetailRow(
      title: context.appLocalizations.proxyChains,
      value: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (index, chain) in trackerInfo.chains.reversed.indexed)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                if (index > 0) const RecordArrow(),
                Flexible(child: MetaChip(label: chain)),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRows(List<(String, String)> entries) {
    return [
      for (final (title, value) in entries)
        if (value.isNotEmpty) DetailRow.text(title: title, value: value),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final metadata = trackerInfo.metadata;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ).copyWith(bottom: 20, top: context.contentTopPadding),
      children: [
        generateSectionV3(
          title: appLocalizations.basicInfo,
          items: _buildRows([
            (appLocalizations.creationTime, trackerInfo.start.showFull),
            (appLocalizations.networkType, metadata.network),
            (appLocalizations.process, trackerInfo.progressText),
            (appLocalizations.rule, _ruleText(trackerInfo)),
            (appLocalizations.upload, trackerInfo.upload.traffic.show),
            (appLocalizations.download, trackerInfo.download.traffic.show),
          ]),
        ),
        generateSectionV3(
          title: appLocalizations.address,
          items: _buildRows([
            (appLocalizations.host, metadata.host),
            (
              appLocalizations.source,
              _endpointText(metadata.sourceIP, metadata.sourcePort),
            ),
            (
              appLocalizations.destination,
              _endpointText(metadata.destinationIP, metadata.destinationPort),
            ),
            (
              appLocalizations.destinationGeoIP,
              metadata.destinationGeoIP.join(' '),
            ),
            (appLocalizations.destinationIPASN, metadata.destinationIPASN),
            (appLocalizations.remoteDestination, metadata.remoteDestination),
          ]),
        ),
        generateSectionV3(
          title: appLocalizations.proxies,
          items: [
            ..._buildRows([
              (appLocalizations.specialProxy, metadata.specialProxy),
              (appLocalizations.specialRules, metadata.specialRules),
              (appLocalizations.dnsMode, metadata.dnsMode?.name ?? ''),
            ]),
            _buildChains(context),
          ],
        ),
      ],
    );
  }
}
