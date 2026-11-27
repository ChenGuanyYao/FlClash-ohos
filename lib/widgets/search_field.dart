import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:material_ui/material_ui.dart';

/// Below this many items a sheet is short enough to scan without a search.
const sheetSearchMinItemCount = 10;

class SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? style;
  final double iconSize;

  const SearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hintText,
    this.style,
    this.iconSize = 20,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (_, value, _) {
        return TextField(
          controller: _controller,
          style: widget.style,
          focusNode: widget.focusNode,
          textInputAction: TextInputAction.search,
          inputFormatters: TextInputLimits.limit(TextInputLimits.search),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hintText ?? appLocalizations.search,
            prefixIcon: GlyphIcon(AppGlyphs.search, size: widget.iconSize),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: appLocalizations.clearSearch,
                    onPressed: _handleClear,
                    icon: const GlyphIcon(AppGlyphs.close, size: 20),
                  ),
          ),
        );
      },
    );
  }
}
