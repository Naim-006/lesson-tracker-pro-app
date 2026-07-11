import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class ProgressSyllabusScreen extends ConsumerStatefulWidget {
  const ProgressSyllabusScreen({super.key});

  @override
  ConsumerState<ProgressSyllabusScreen> createState() => _ProgressSyllabusScreenState();
}

class _ProgressSyllabusScreenState extends ConsumerState<ProgressSyllabusScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', user.id)
          .order('order_index', ascending: true);

      final list = List<Map<String, dynamic>>.from(response);

      if (list.isEmpty && mounted) {
        await _seedDefaults(user.id);
      } else if (mounted) {
        setState(() {
          _categories = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _seedDefaults(String instructorId) async {
    setState(() => _seeding = true);
    try {
      await Supabase.instance.client.rpc(
        'seed_default_progress_categories',
        params: {'p_instructor_id': instructorId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default syllabus created')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _seeding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  List<String> _skillList(Map<String, dynamic> cat) {
    final desc = cat['description'] as String? ?? '';
    if (desc.isEmpty) return [];
    return desc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String _skillsToDb(List<String> skills) => skills.join(',');

  Future<void> _addCategory() async {
    final titleCtrl = TextEditingController();
    final skillCtrl = TextEditingController();
    final skills = <String>[];
    final skillFocus = FocusNode();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_outlined, color: AppColors.sunsetBright, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Add Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Category name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  Text('Skills', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  if (skills.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(skills.length, (i) {
                        return Chip(
                          label: Text(skills[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setLocalState(() => skills.removeAt(i)),
                          backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.08),
                          side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: skillCtrl,
                          focusNode: skillFocus,
                          decoration: InputDecoration(
                            hintText: 'Enter a skill',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (v) {
                            final trimmed = v.trim();
                            if (trimmed.isNotEmpty && !skills.contains(trimmed)) {
                              setLocalState(() => skills.add(trimmed));
                              skillCtrl.clear();
                              skillFocus.requestFocus();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
                          onPressed: () {
                            final trimmed = skillCtrl.text.trim();
                            if (trimmed.isNotEmpty && !skills.contains(trimmed)) {
                              setLocalState(() => skills.add(trimmed));
                              skillCtrl.clear();
                              skillFocus.requestFocus();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: titleCtrl.text.trim().isNotEmpty ? () => Navigator.pop(ctx, true) : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('progress_categories').insert({
        'instructor_id': user.id,
        'title': titleCtrl.text.trim(),
        'description': _skillsToDb(skills),
        'order_index': _categories.length,
      });

      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> cat) async {
    final titleCtrl = TextEditingController(text: cat['title'] as String? ?? '');
    final skillCtrl = TextEditingController();
    final skills = List<String>.from(_skillList(cat));
    final skillFocus = FocusNode();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.sunsetBright, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Edit Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Category name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Skills (${skills.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (skills.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(skills.length, (i) {
                        return Chip(
                          label: Text(skills[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setLocalState(() => skills.removeAt(i)),
                          backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.08),
                          side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('No skills defined yet.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: skillCtrl,
                          focusNode: skillFocus,
                          decoration: InputDecoration(
                            hintText: 'Add a skill',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (v) {
                            final trimmed = v.trim();
                            if (trimmed.isNotEmpty && !skills.contains(trimmed)) {
                              setLocalState(() => skills.add(trimmed));
                              skillCtrl.clear();
                              skillFocus.requestFocus();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
                          onPressed: () {
                            final trimmed = skillCtrl.text.trim();
                            if (trimmed.isNotEmpty && !skills.contains(trimmed)) {
                              setLocalState(() => skills.add(trimmed));
                              skillCtrl.clear();
                              skillFocus.requestFocus();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: titleCtrl.text.trim().isNotEmpty ? () => Navigator.pop(ctx, true) : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await Supabase.instance.client
          .from('progress_categories')
          .update({
            'title': titleCtrl.text.trim(),
            'description': _skillsToDb(skills),
          })
          .eq('id', cat['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat['title']}" and all its skills? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('progress_categories').delete().eq('id', cat['id']);
      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Progress Syllabus', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _seeding ? null : _addCategory,
              tooltip: 'Add category',
            ),
          ),
        ],
      ),
      body: _loading || _seeding
          ? Center(
              child: _seeding
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.sunsetBright),
                        const SizedBox(height: 16),
                        Text('Creating default syllabus...',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    )
                  : const CircularProgressIndicator(color: AppColors.sunsetBright),
            )
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No categories yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap + to create your first skill category',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _categories.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _addCategory,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Category'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.5)),
                            foregroundColor: AppColors.sunsetBright,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      );
                    }

                    final cat = _categories[index];
                    final skills = _skillList(cat);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.sunsetBright,
                                          AppColors.sunsetBright.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat['title'] as String? ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                        Text(
                                          '${skills.length} ${skills.length == 1 ? 'skill' : 'skills'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.sunsetBright.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      color: AppColors.sunsetBright,
                                      onPressed: () => _editCategory(cat),
                                      tooltip: 'Edit',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      color: AppColors.error,
                                      onPressed: () => _deleteCategory(cat),
                                      tooltip: 'Delete',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (skills.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills.map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.sunsetBright.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.sunsetBright.withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Text(
                                        skill,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.sunsetBright,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
