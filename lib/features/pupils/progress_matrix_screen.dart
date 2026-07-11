import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class ProgressMatrixScreen extends ConsumerStatefulWidget {
  const ProgressMatrixScreen({super.key, required this.pupil});

  final Pupil pupil;

  @override
  ConsumerState<ProgressMatrixScreen> createState() => _ProgressMatrixScreenState();
}

class _ProgressMatrixScreenState extends ConsumerState<ProgressMatrixScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final categoriesResponse = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', user.id)
          .order('order_index', ascending: true);

      final categories = List<Map<String, dynamic>>.from(categoriesResponse);

      var skills = await Supabase.instance.client
          .from('progress_skills')
          .select('*')
          .eq('pupil_id', widget.pupil.id);

      var skillsList = List<Map<String, dynamic>>.from(skills);

      // Auto-create missing skills from category descriptions
      if (skillsList.isEmpty && categories.isNotEmpty) {
        for (final cat in categories) {
          final desc = cat['description'] as String? ?? '';
          if (desc.isEmpty) continue;
          final skillNames = desc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          for (var i = 0; i < skillNames.length; i++) {
            await Supabase.instance.client.from('progress_skills').insert({
              'category_id': cat['id'],
              'pupil_id': widget.pupil.id,
              'title': skillNames[i],
              'skill_level': 0,
              'order_index': i,
            });
          }
        }
        // Reload skills after creation
        skills = await Supabase.instance.client
            .from('progress_skills')
            .select('*')
            .eq('pupil_id', widget.pupil.id);
        skillsList = List<Map<String, dynamic>>.from(skills);
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _skills = skillsList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading progress: ${userFriendlyError(e)}')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _skillsForCategory(String categoryId) {
    return _skills
        .where((s) => s['category_id'] == categoryId)
        .toList()
      ..sort((a, b) => (a['order_index'] as int? ?? 0).compareTo(b['order_index'] as int? ?? 0));
  }

  double _overallProgress() {
    if (_skills.isEmpty) return 0.0;
    final total = _skills.fold<double>(0, (sum, s) => sum + ((s['skill_level'] as int?) ?? 0));
    return total / (_skills.length * 5);
  }

  double _categoryProgress(String categoryId) {
    final list = _skillsForCategory(categoryId);
    if (list.isEmpty) return 0.0;
    final total = list.fold<double>(0, (sum, s) => sum + ((s['skill_level'] as int?) ?? 0));
    return total / (list.length * 5);
  }

  Future<void> _setSkillLevel(Map<String, dynamic> skill, int level) async {
    final current = (skill['skill_level'] as int?) ?? 0;
    final newLevel = current == level ? 0 : level;
    final skillId = skill['id'] as String;

    setState(() {
      final index = _skills.indexWhere((s) => s['id'] == skillId);
      if (index >= 0) {
        _skills[index] = {
          ..._skills[index],
          'skill_level': newLevel,
          'last_practiced': DateTime.now().toIso8601String(),
        };
      }
    });

    try {
      await Supabase.instance.client
          .from('progress_skills')
          .update({
            'skill_level': newLevel,
            'last_practiced': DateTime.now().toIso8601String(),
          })
          .eq('id', skillId);
      ref.invalidate(pupilProgressSkillsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating skill: ${userFriendlyError(e)}')),
        );
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completion = _overallProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Matrix'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _EmptyState(
                  icon: Icons.category_outlined,
                  message: 'No categories set up yet.\nGo to Settings → Syllabus to create them.',
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).cardColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Overall Progress',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${(completion * 100).toStringAsFixed(0)}%'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completion,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completion == 1.0 ? AppColors.success : AppColors.sunsetBright,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.sunsetBright,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: _categories.length,
                          itemBuilder: (context, i) {
                            final cat = _categories[i];
                            final skills = _skillsForCategory(cat['id'] as String);
                            final progress = _categoryProgress(cat['id'] as String);

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Text(
                                    cat['title'] ?? 'Category',
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: const AlwaysStoppedAnimation(
                                                  AppColors.sunsetBright),
                                              minHeight: 5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.sunsetBright,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  children: skills.isEmpty
                                      ? [
                                          const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text('No skills in this category.',
                                                style: TextStyle(color: Colors.grey)),
                                          ),
                                        ]
                                      : skills.map((skill) => _SkillRow(
                                            skill: skill,
                                            onLevelSelected: (level) =>
                                                _setSkillLevel(skill, level),
                                          )).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.onLevelSelected});

  final Map<String, dynamic> skill;
  final ValueChanged<int> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final level = (skill['skill_level'] as int?) ?? 0;
    final notes = skill['description'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill['title'] ?? 'Skill',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          notes,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$level / 5',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sunsetBright),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) {
                final btnScore = index + 1;
                final isSelected = btnScore <= level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onLevelSelected(btnScore),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.success : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppColors.success)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '$btnScore',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
