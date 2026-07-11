import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class PupilProgressScreen extends StatefulWidget {
  const PupilProgressScreen({super.key});

  @override
  State<PupilProgressScreen> createState() => _PupilProgressScreenState();
}

class _PupilProgressScreenState extends State<PupilProgressScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    if (user == null) return;
    try {
      final linkResponse = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();

      if (linkResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final instructorId = linkResponse['instructor_id'];

      final categoriesResponse = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', instructorId)
          .order('order_index', ascending: true);

      final skillsResponse = await Supabase.instance.client
          .from('progress_skills')
          .select('*, progress_categories!inner(title)')
          .eq('pupil_id', user!.id);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesResponse);
          _skills = List<Map<String, dynamic>>.from(skillsResponse);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _overallProgress() {
    if (_skills.isEmpty) return 0.0;
    final total = _skills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return total / (_skills.length * 5);
  }

  List<Map<String, dynamic>> _skillsForCategory(String categoryId) =>
      _skills.where((s) => s['category_id'] == categoryId).toList();

  double _categoryProgress(String categoryId) {
    final list = _skillsForCategory(categoryId);
    if (list.isEmpty) return 0.0;
    final total = list.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return total / (list.length * 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overall = _overallProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : _categories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up_rounded, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No Progress Data',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text('Your instructor will assign skills to track.',
                            style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProgressData,
                  color: AppColors.sunsetBright,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text('${(overall * 100).toInt()}%',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.sunsetBright)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: overall,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._categories.map((cat) {
                        final skills = _skillsForCategory(cat['id'] as String);
                        final progress = _categoryProgress(cat['id'] as String);
                        return _CategoryCard(
                          category: cat,
                          progress: progress,
                          skills: skills,
                          isDark: isDark,
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.progress, required this.skills, required this.isDark});
  final Map<String, dynamic> category;
  final double progress;
  final List<Map<String, dynamic>> skills;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
          ),
          title: Text(category['title'] ?? 'Category',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
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
                      valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
              ],
            ),
          ),
          children: skills.isEmpty
              ? [const Padding(padding: EdgeInsets.all(16), child: Text('No skills', style: TextStyle(color: Colors.grey)))]
              : [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: skills.map((skill) {
                        final level = (skill['skill_level'] as int?) ?? 0;
                        final practiced = skill['last_practiced'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(skill['title'] ?? 'Skill',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                                    if (practiced != null) ...[
                                      const SizedBox(height: 2),
                                      Text('Last practiced: ${_formatDate(practiced.toString())}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 3),
                                    child: Icon(
                                      i < level ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 18,
                                      color: i < level ? const Color(0xFFFBBF24) : Colors.grey.shade300,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
