import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'interface_icons.dart';

class ProfilePageTitle extends ConsumerWidget {
  const ProfilePageTitle({
    super.key,
    required this.title,
    this.showBrand = false,
  });
  final String title;
  final bool showBrand;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(
      currentProfileProvider.select((value) => value?.realLabel),
    );
    final scheme = context.colorScheme;
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 30) return const SizedBox.shrink();
        final showLabel = !showBrand || constraints.maxWidth >= 160;
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurface,
            minimumSize: const Size(0, 48),
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerStart,
          ),
          onPressed: () => ref
              .read(currentPageLabelProvider.notifier)
              .toPage(PageLabel.profiles),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBrand) ...[
                Semantics(
                  image: true,
                  label: showLabel ? null : title,
                  child: const InterfaceBrandGlyph(),
                ),
                if (showLabel) const SizedBox(width: 11),
              ],
              if (showLabel)
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: enlarged ? 0 : 6),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontSize: enlarged ? 22 : 24,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: enlarged ? 3 : (context.isMobileView ? 9 : 5),
                      ),
                      Transform.translate(
                        offset: Offset(0, enlarged ? 0 : 3.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                profile ?? context.appLocalizations.addProfile,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (constraints.maxWidth > 80) ...[
                              const SizedBox(width: 5),
                              GlyphIcon(
                                AppGlyphs.chevronDown,
                                size: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
