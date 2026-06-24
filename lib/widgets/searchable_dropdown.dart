import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Normalises a string for forgiving, language-agnostic search.
///
/// - lowercases (English)
/// - strips Arabic diacritics (tashkeel) and tatweel
/// - unifies alef variants (أ إ آ → ا), alef-maksura (ى → ي) and teh-marbuta
///   (ة → ه) so users don't have to type the exact form.
String normalizeSearch(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceAll(RegExp('[ً-ٰٟ]'), ''); // tashkeel
  s = s.replaceAll('ـ', ''); // tatweel
  s = s.replaceAll(RegExp('[آأإ]'), 'ا'); // alef variants
  s = s.replaceAll('ى', 'ي'); // alef maksura -> yaa
  s = s.replaceAll('ة', 'ه'); // teh marbuta -> haa
  return s;
}

/// One selectable option. [value] is both shown and returned on selection;
/// [searchText] is the pre-normalised text matched against the query (it should
/// contain BOTH the Arabic and English names); [subtitle] is an optional
/// secondary line (e.g. the name in the other language).
class SearchableItem {
  final String value;
  final String searchText;
  final String? subtitle;

  const SearchableItem({
    required this.value,
    required this.searchText,
    this.subtitle,
  });
}

/// A dropdown-like field that opens a searchable bottom sheet. Drop-in
/// replacement for [DropdownButtonFormField] usage where the selected value is
/// a display string.
class SearchableDropdown extends StatelessWidget {
  final String hint;
  final String searchHint;
  final IconData? icon;
  final String? value;
  final List<SearchableItem> items;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const SearchableDropdown({
    super.key,
    required this.hint,
    required this.searchHint,
    required this.items,
    required this.onSelected,
    this.icon,
    this.value,
    this.enabled = true,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(
        title: hint,
        searchHint: searchHint,
        items: items,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled ? () => _openPicker(context) : null,
        child: InputDecorator(
          isEmpty: !hasValue,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: const Icon(Icons.search),
          ),
          child: hasValue
              ? Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<SearchableItem> items;

  const _SearchSheet({
    required this.title,
    required this.searchHint,
    required this.items,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = normalizeSearch(_query);
    final filtered = normalizedQuery.isEmpty
        ? widget.items
        : widget.items
            .where((i) => i.searchText.contains(normalizedQuery))
            .toList();

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                  AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _query = ''),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No results',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item.value),
                          subtitle: (item.subtitle != null &&
                                  item.subtitle!.isNotEmpty)
                              ? Text(item.subtitle!)
                              : null,
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.neutral),
                          onTap: () => Navigator.of(context).pop(item.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
