import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/widget_metrics.dart';
import 'package:fl_clash/views/profiles/add.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_detail.dart';

class ProfilesCard extends ConsumerWidget {
  const ProfilesCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    final canSwitch = ref.watch(
      profilesProvider.select((profiles) => profiles.length > 1),
    );
    final scheme = context.colorScheme;
    final padding = DashboardWidgetMetrics.paddingOf(context);
    return Tooltip(
      message: profile?.realLabel ?? labels.addProfile,
      child: SizedBox(
        height: DashboardWidgetMetrics.heightOf(context, 1.65, textHeight: 96),
        child: CommonCard(
          radius: DashboardWidgetMetrics.radiusOf(context),
          onPressed: profile == null
              ? showAddProfilePage
              : () => showProfileDetailSheet(context),
          child: Column(
            children: [
              InfoHeader(
                info: Info(label: labels.remainingTraffic),
                padding: padding.copyWith(top: 16, bottom: 8),
                textStyle: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                actions: [
                  if (canSwitch)
                    AspectRatio(
                      aspectRatio: 1,
                      child: IconButton.filledTonal(
                        tooltip: labels.switchProfile,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest,
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => _showPicker(context),
                        icon: GlyphIcon(AppGlyphs.picker, size: 16.ap, fill: 1),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: padding.copyWith(top: 0, bottom: 8),
                  child: _ProfileQuota(profile: profile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileQuota extends StatelessWidget {
  const _ProfileQuota({required this.profile});
  final Profile? profile;
  @override
  Widget build(BuildContext context) {
    final current = profile;
    final info = current?.subscriptionInfo;
    final labels = context.appLocalizations;
    final scheme = context.colorScheme;
    final style = context.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final hasQuota = info != null && info.total > 0;
    final used = hasQuota ? info.upload + info.download : 0;
    final remaining = hasQuota
        ? (info.total - used).clamp(0, info.total).toInt()
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        if (hasQuota)
          Tooltip(
            message: '${used.traffic.show} / ${info.total.traffic.show}',
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: remaining.traffic.value,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(text: ' ${remaining.traffic.unit}', style: style),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            current == null ? labels.addProfile : labels.noInfo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        const Spacer(),
        if (hasQuota) ...[
          LinearProgressIndicator(
            value: (remaining / info.total).clamp(0.0, 1.0),
            minHeight: 3,
            color: scheme.primary,
            backgroundColor: scheme.surfaceContainerHigh,
            borderRadius: AppRadius.full,
            semanticsLabel: labels.remainingTraffic,
          ),
          const SizedBox(height: 22),
          Text(
            '${labels.total} ${info.total.traffic.show}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ] else if (current != null) ...[
          Text(
            labels.lastUpdated,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: style,
            child: LastUpdateTimeText(lastUpdateDate: current.lastUpdateDate),
          ),
        ],
      ],
    );
  }
}

void _showPicker(BuildContext context) {
  showSheet<void>(
    context: context,
    builder: (_) => const _ProfilePickerSheet(),
  );
}

class _ProfilePickerSheet extends ConsumerWidget {
  const _ProfilePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    final currentId = ref.watch(currentProfileIdProvider);
    void select(int? profileId) {
      if (profileId != null) {
        ref.read(currentProfileIdProvider.notifier).value = profileId;
      }
      Navigator.of(context).pop();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: ref.sheetHeight(context, 0.7)),
      child: CommonScaffold(
        title: context.appLocalizations.switchProfile,
        body: RadioGroup<int>(
          groupValue: currentId,
          onChanged: select,
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, context.contentTopPadding, 16, 16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return ItemPositionProvider(
                position: ItemPosition.get(index, profiles.length),
                child: ListItem.radio(
                  value: profile.id,
                  onTap: () => select(profile.id),
                  title: EmojiText(
                    profile.realLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
