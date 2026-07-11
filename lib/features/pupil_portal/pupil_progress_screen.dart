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
    _load();
  }

  Future<void> _load() async {
    if (user == null) return;
    try {
      final link = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();

      if (link == null) { if (mounted) setState(() => _isLoading = false); return; }

      final cats = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', link['instructor_id'])
          .order('order_index', ascending: true);

      final skills = await Supabase.instance.client
          .from('progress_skills')
          .select('*, progress_categories!inner(title)')
          .eq('pupil_id', user!.id);

      if (mounted) setState(() { _categories = List<Map<String, dynamic>>.from(cats); _skills = List<Map<String, dynamic>>.from(skills); _isLoading = false; });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  double get _overall {
    if (_skills.isEmpty) return 0.0;
    return _skills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (_skills.length * 5);
  }

  List<Map<String, dynamic>> _skillsFor(String catId) => _skills.where((s) => s['category_id'] == catId).toList();

  double _catProgress(String catId) {
    final list = _skillsFor(catId);
    if (list.isEmpty) return 0.0;
    return list.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (list.length * 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overall = _overall;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : _categories.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No Progress Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Text('Your instructor will set up skills to track.', style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.sunsetBright,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Overall Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                              Text('${(overall * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1)),
                            ]),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: overall,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._categories.map((cat) {
                        final skills = _skillsFor(cat['id'] as String);
                        final progress = _catProgress(cat['id'] as String);
                        return _CatCard(category: cat, progress: progress, skills: skills, isDark: isDark);
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _CatCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final double progress;
  final List<Map<String, dynamic>> skills;
  final bool isDark;

  const _CatCard({required this.category, required this.progress, required this.skills, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(
              (category['title'] as String? ?? '?')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
            )),
          ),
          title: Text(category['title'] ?? 'Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright), minHeight: 6),
                )),
                const SizedBox(width: 12),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
              ],
            ),
          ),
          children: skills.isEmpty
              ? [const Padding(padding: EdgeInsets.all(12), child: Text('No skills', style: TextStyle(color: Colors.grey)))]
              : skills.map((s) {
                  final level = (s['skill_level'] as int?) ?? 0;
                  final practiced = s['last_practiced'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['title'] ?? 'Skill', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                              if (practiced != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('Practiced: ${_formatDate(practiced.toString())}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Icon(i < level ? Icons.star_rounded : Icons.star_border_rounded, size: 20, color: i < level ? const Color(0xFFFBBF24) : Colors.grey.shade300),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
