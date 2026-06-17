import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      // Get linked instructor
      final linkResponse = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();

      if (linkResponse == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final instructorId = linkResponse['instructor_id'];

      // Load progress categories
      final categoriesResponse = await Supabase.instance.client
          .from('progress_categories')
          .select('*')
          .eq('instructor_id', instructorId)
          .order('order_index', ascending: true);

      // Load progress skills
      final skillsResponse = await Supabase.instance.client
          .from('progress_skills')
          .select('*, progress_categories!inner(name)')
          .eq('pupil_id', user!.id);

      setState(() {
        _categories = List<Map<String, dynamic>>.from(categoriesResponse);
        _skills = List<Map<String, dynamic>>.from(skillsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSkillsForCategory(String categoryId) {
    return _skills.where((skill) => skill['category_id'] == categoryId).toList();
  }

  double _calculateCategoryProgress(String categoryId) {
    final categorySkills = _getSkillsForCategory(categoryId);
    if (categorySkills.isEmpty) return 0.0;
    
    final total = categorySkills.fold<double>(0, (sum, skill) => sum + (skill['skill_level'] as int));
    return total / (categorySkills.length * 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildNoInstructorView()
              : RefreshIndicator(
                  onRefresh: _loadProgressData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final progress = _calculateCategoryProgress(category['id']);
                      final skills = _getSkillsForCategory(category['id']);

                      return _CategoryCard(
                        category: category,
                        progress: progress,
                        skills: skills,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildNoInstructorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Instructor Linked',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Link with an instructor to track your progress',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to find tutors
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Find an Instructor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.progress,
    required this.skills,
  });

  final Map<String, dynamic> category;
  final double progress;
  final List<Map<String, dynamic>> skills;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: Colors.green,
          ),
        ),
        title: Text(
          category['name'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          if (skills.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No skills recorded yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: skills.map((skill) => _SkillTile(skill: skill)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.skill});

  final Map<String, dynamic> skill;

  @override
  Widget build(BuildContext context) {
    final level = skill['skill_level'] as int;
    final lastPracticed = skill['last_practiced'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  skill['skill_name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < level ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < level ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
          if (skill['notes'] != null && skill['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              skill['notes'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (lastPracticed != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last practiced: ${_formatDate(lastPracticed)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
