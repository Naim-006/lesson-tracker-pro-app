import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class PupilJourneyScreen extends StatefulWidget {
  const PupilJourneyScreen({super.key});

  @override
  State<PupilJourneyScreen> createState() => _PupilJourneyScreenState();
}

class _PupilJourneyScreenState extends State<PupilJourneyScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    try {
      final linkRes = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', _user!.id)
          .eq('status', 'active')
          .maybeSingle();

      if (linkRes == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final catsRes = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', linkRes['instructor_id'])
          .order('order_index', ascending: true);

      final skillsRes = await Supabase.instance.client
          .from('progress_skills')
          .select('*, progress_categories!inner(name)')
          .eq('pupil_id', _user!.id);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(catsRes);
          _skills = List<Map<String, dynamic>>.from(skillsRes);
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

  double _categoryProgress(String catId) {
    final catSkills = _skills.where((s) => s['category_id'] == catId).toList();
    if (catSkills.isEmpty) return 0.0;
    final total = catSkills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return total / (catSkills.length * 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _overallProgress();

    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.sunsetBright,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(isDark)),
                SliverToBoxAdapter(child: _buildProgressRing(progress, isDark)),
                SliverToBoxAdapter(child: _buildStatsRow(isDark)),
                SliverToBoxAdapter(child: _buildCategories(isDark)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        'Your Journey',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildProgressRing(double progress, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunsetBright.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: progress,
                        color: AppColors.sunsetBright,
                        bgColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getEncouragement(progress),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.sunsetBright,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEncouragement(double p) {
    if (p >= 0.9) return "Almost there! You're a star!";
    if (p >= 0.7) return 'Great progress! Keep it up!';
    if (p >= 0.4) return "You're doing well. Keep practicing!";
    if (p >= 0.1) return 'Good start! Keep going!';
    return 'Your journey begins here!';
  }

  Widget _buildStatsRow(bool isDark) {
    final totalSkills = _skills.length;
    final mastered = _skills.where((s) => (s['skill_level'] as int? ?? 0) >= 5).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _MiniStat(
            value: '$totalSkills',
            label: 'Skills',
            color: AppColors.sunsetBright,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _MiniStat(
            value: '$mastered',
            label: 'Mastered',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _MiniStat(
            value: '${_categories.length}',
            label: 'Categories',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(bool isDark) {
    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.explore_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No progress data yet',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ..._categories.map((cat) {
            final catId = cat['id'];
            final catSkills = _skills.where((s) => s['category_id'] == catId).toList();
            final catProgress = _categoryProgress(catId);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.category_rounded, color: AppColors.sunsetBright, size: 22),
                  ),
                  title: Text(
                    cat['name'] ?? 'Category',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: catProgress,
                              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(catProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sunsetBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: catSkills.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No skills recorded yet',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ),
                        ]
                      : catSkills.map((skill) {
                          final level = (skill['skill_level'] as int?) ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        skill['skill_name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                                        ),
                                      ),
                                      if (skill['notes'] != null && skill['notes'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          skill['notes'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 2),
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
            );
          }),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label, required this.color, required this.isDark});
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ProgressRingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
