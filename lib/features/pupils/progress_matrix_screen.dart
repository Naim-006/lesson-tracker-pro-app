import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class ProgressMatrixScreen extends ConsumerStatefulWidget {
  const ProgressMatrixScreen({super.key, required this.pupil});

  final Pupil pupil;

  @override
  ConsumerState<ProgressMatrixScreen> createState() => _ProgressMatrixScreenState();
}

class _ProgressMatrixScreenState extends ConsumerState<ProgressMatrixScreen> {
  late int _scaleType;
  late Map<String, Map<String, int>> _scores;

  final List<ProgressCategory> _categories = [
    ProgressCategory(
      id: 'cat1',
      title: 'Preparation',
      skills: [
        ProgressSkill(id: 's1', title: 'Cockpit drill'),
        ProgressSkill(id: 's2', title: 'Controls & instruments'),
        ProgressSkill(id: 's3', title: 'Moving away & stopping'),
      ],
    ),
    ProgressCategory(
      id: 'cat2',
      title: 'Traffic Management',
      skills: [
        ProgressSkill(id: 's4', title: 'Mirrors & vision'),
        ProgressSkill(id: 's5', title: 'Signals'),
        ProgressSkill(id: 's6', title: 'Clearance & speed'),
      ],
    ),
    ProgressCategory(
      id: 'cat3',
      title: 'Junctions',
      skills: [
        ProgressSkill(id: 's7', title: 'T-Junctions'),
        ProgressSkill(id: 's8', title: 'Crossroads'),
        ProgressSkill(id: 's9', title: 'Roundabouts'),
      ],
    ),
    ProgressCategory(
      id: 'cat4',
      title: 'Maneuvers',
      skills: [
        ProgressSkill(id: 's10', title: 'Parallel parking'),
        ProgressSkill(id: 's11', title: 'Bay parking'),
        ProgressSkill(id: 's12', title: 'Turn in road'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scaleType = widget.pupil.progressScaleType;
    _scores = Map.from(widget.pupil.progressScores).map((k, v) => MapEntry(k, Map.from(v)));
  }

  Future<void> _save() async {
    try {
      await Supabase.instance.client.from('pupils').update({
        'progress_scale_type': _scaleType,
        'progress_scores': _scores,
      }).eq('id', widget.pupil.id);

      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving progress: $e')),
        );
      }
    }
  }

  void _setScore(String catId, String skillId, int score) {
    setState(() {
      _scores.putIfAbsent(catId, () => {});
      _scores[catId]![skillId] = score;
    });
  }

  int _getScore(String catId, String skillId) {
    return _scores[catId]?[skillId] ?? 0;
  }

  void _showAddCategoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final skillsController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Dual Carriageways'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills (one per line)',
                  hintText: 'Lane discipline\nSpeed awareness\n...',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final skills = skillsController.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final catId = DateTime.now().millisecondsSinceEpoch.toString();
                final cat = ProgressCategory(
                  id: catId,
                  title: titleController.text.trim(),
                  skills: skills.map((s) => ProgressSkill(
                    id: '${catId}_${s.toLowerCase().replaceAll(' ', '_')}',
                    title: s,
                  )).toList(),
                );
                setState(() => _categories.add(cat));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  double _calculateCompletion() {
    int total = 0;
    int maxPossible = 0;
    for (final cat in _categories) {
      for (final s in cat.skills) {
        maxPossible += _scaleType;
        total += _getScore(cat.id, s.id);
      }
    }
    if (maxPossible == 0) return 0.0;
    return total / maxPossible;
  }

  @override
  Widget build(BuildContext context) {
    final completion = _calculateCompletion();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
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
                    const Text('Global Completion', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Scale:'),
                    DropdownButton<int>(
                      value: _scaleType,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('1 - 3 (Basic)')),
                        DropdownMenuItem(value: 5, child: Text('1 - 5 (Standard)')),
                        DropdownMenuItem(value: 10, child: Text('1 - 10 (Advanced)')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _scaleType = v;
                            // Need to cap existing scores
                            _scores.forEach((cId, skills) {
                              skills.forEach((sId, score) {
                                if (score > v) skills[sId] = v;
                              });
                            });
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length + 2,
              itemBuilder: (context, i) {
                if (i == _categories.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                  );
                }
                if (i == _categories.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 32),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Progress'),
                      onPressed: _save,
                    ),
                  );
                }

                final cat = _categories[i];
                return ExpansionTile(
                  title: Text(cat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: cat.skills.map((skill) {
                    final score = _getScore(cat.id, skill.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(skill.title)),
                              Text('$score / $_scaleType', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(_scaleType, (index) {
                                final btnScore = index + 1;
                                final isSelected = btnScore <= score;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () {
                                      // Toggle off if clicking the current score
                                      if (score == btnScore) {
                                        _setScore(cat.id, skill.id, 0);
                                      } else {
                                        _setScore(cat.id, skill.id, btnScore);
                                      }
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.success : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: isSelected ? Border.all(color: AppColors.success) : Border.all(color: Colors.grey.shade300),
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
                          const Divider(height: 24),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
