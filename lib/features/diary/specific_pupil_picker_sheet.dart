import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SelectablePupil {
  const SelectablePupil({
    required this.id,
    required this.fullName,
    required this.sortDate,
  });

  final String id;
  final String fullName;
  final DateTime sortDate;
}

enum _PupilSort { newest, oldest }

/// Half-screen scrollable multi-select picker for specific pupils.
Future<Set<String>?> showSpecificPupilPicker({
  required BuildContext context,
  required List<SelectablePupil> pupils,
  required Set<String> initialSelection,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SpecificPupilPickerSheet(
      pupils: pupils,
      initialSelection: initialSelection,
    ),
  );
}

class _SpecificPupilPickerSheet extends StatefulWidget {
  const _SpecificPupilPickerSheet({
    required this.pupils,
    required this.initialSelection,
  });

  final List<SelectablePupil> pupils;
  final Set<String> initialSelection;

  @override
  State<_SpecificPupilPickerSheet> createState() => _SpecificPupilPickerSheetState();
}

class _SpecificPupilPickerSheetState extends State<_SpecificPupilPickerSheet> {
  late Set<String> _selected;
  _PupilSort _sort = _PupilSort.newest;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  List<SelectablePupil> get _filtered {
    final q = _query.trim().toLowerCase();
    var list = widget.pupils.where((p) {
      if (q.isEmpty) return true;
      return p.fullName.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      final cmp = a.sortDate.compareTo(b.sortDate);
      return _sort == _PupilSort.newest ? -cmp : cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select pupils',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(
                          '${_selected.length} selected',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selected.length == filtered.length) {
                          _selected.clear();
                        } else {
                          _selected.addAll(filtered.map((p) => p.id));
                        }
                      });
                    },
                    child: Text(
                      _selected.length == filtered.length && filtered.isNotEmpty
                          ? 'Clear all'
                          : 'Select all',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search pupils…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Sort', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Newest'),
                    selected: _sort == _PupilSort.newest,
                    onSelected: (_) => setState(() => _sort = _PupilSort.newest),
                    selectedColor: AppColors.sunsetBright.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Oldest'),
                    selected: _sort == _PupilSort.oldest,
                    onSelected: (_) => setState(() => _sort = _PupilSort.oldest),
                    selectedColor: AppColors.sunsetBright.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.pupils.isEmpty ? 'No active pupils found' : 'No matches',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final pupil = filtered[index];
                        final isSelected = _selected.contains(pupil.id);
                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: AppColors.sunsetBright,
                          title: Text(pupil.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            _sort == _PupilSort.newest ? 'Added recently' : 'Added earlier',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(pupil.id);
                              } else {
                                _selected.add(pupil.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.pop(context, _selected),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
                      child: Text('Done (${_selected.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
