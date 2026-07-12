import 'dart:math';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (user == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final link = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();
      if (link == null) { setState(() { _isLoading = false; _error = 'Could not load instructor link.'; }); return; }

      final cats = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', link['instructor_id'])
          .order('order_index', ascending: true);
      final skillsRes = await Supabase.instance.client
          .from('progress_skills')
          .select('*, progress_categories!inner(title)')
          .eq('pupil_id', user!.id);

      setState(() { _categories = List<Map<String, dynamic>>.from(cats); _skills = List<Map<String, dynamic>>.from(skillsRes); _isLoading = false; });
    } catch (_) { setState(() { _isLoading = false; _error = 'Could not load progress data.'; }); }
  }

  double get _overall {
    if (_skills.isEmpty) return 0;
    final t = _skills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return t / (_skills.length * 5);
  }

  double _catProgress(String catId) {
    final list = _skills.where((s) => s['category_id'] == catId).toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (list.length * 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F5F2),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _header(isDark),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)))
          else if (_error != null)
            SliverFillRemaining(child: _errorWidget())
          else if (_categories.isEmpty)
            SliverFillRemaining(child: _empty())
          else ...[
            SliverToBoxAdapter(child: _progressRingCard(isDark)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => _CategoryCard(category: _categories[i], skills: _skills.where((s) => s['category_id'] == _categories[i]['id']).toList(), progress: _catProgress(_categories[i]['id']), isDark: isDark),
                childCount: _categories.length,
              )),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.sunsetBright,
      foregroundColor: Colors.white,
      title: const Text('My Progress', style: TextStyle(fontWeight: FontWeight.w800)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.sunsetBright, const Color(0xFFE85D3A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
    );
  }

  Widget _progressRingCard(bool isDark) {
    final pct = (_overall * 100).toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            SizedBox(
              width: 100, height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(painter: _Ring(progress: _overall, color: AppColors.sunsetBright, bgColor: Colors.grey.shade200), size: const Size(100, 100)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('$pct%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.sunsetBright)), Text('${_skills.length} skills', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Progress', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Keep practicing!', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                _badge(_skills.where((s) => (s['skill_level'] as int? ?? 0) >= 5).length, Icons.star_rounded, const Color(0xFFFBBF24), 'Mastered'),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _badge(int count, IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text('$count $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))],
      ),
    );
  }

  Widget _empty() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.trending_up_rounded, size: 72, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No Progress Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade500)), const SizedBox(height: 8), Text('Your instructor will assign skills to track.', style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center)])));
  }

  Widget _errorWidget() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(_error!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade500)), const SizedBox(height: 16), FilledButton.tonalIcon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry'))]));
  }
}

class _Ring extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _Ring({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    canvas.drawCircle(center, radius, Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.progress != progress;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.skills, required this.progress, required this.isDark});
  final Map<String, dynamic> category;
  final List<Map<String, dynamic>> skills;
  final double progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
          ),
          title: Text(category['title'] ?? 'Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 6, bottom: 6), child: Row(
            children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright), minHeight: 6))),
              const SizedBox(width: 10),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
            ],
          )),
          children: skills.isEmpty
            ? [const Padding(padding: EdgeInsets.all(18), child: Text('No skills', style: TextStyle(color: Colors.grey)))]
            : [Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: Column(children: skills.map((skill) {
                final level = (skill['skill_level'] as int?) ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Expanded(child: Text(skill['title'] ?? 'Skill', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87))),
                    Row(children: List.generate(5, (i) => Padding(padding: const EdgeInsets.only(left: 2), child: Icon(i < level ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: i < level ? const Color(0xFFFBBF24) : Colors.grey.shade300)))),
                  ]),
                );
              }).toList()))],
        ),
      ),
    );
  }
}