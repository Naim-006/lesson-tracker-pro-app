import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class PupilResourcesScreen extends ConsumerStatefulWidget {
  const PupilResourcesScreen({super.key});

  @override
  ConsumerState<PupilResourcesScreen> createState() => _PupilResourcesScreenState();
}

class _PupilResourcesScreenState extends ConsumerState<PupilResourcesScreen> {
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('teaching_resources')
          .select('''
            id,
            title,
            type,
            category,
            description,
            video_link,
            resource_link,
            share_link,
            visibility,
            selected_pupil_ids,
            created_at,
            profiles(
              full_name
            )
          ''')
          .or('visibility.eq.public,and(visibility.eq.selective,selected_pupil_ids.cs.{${user.id}})')
          .order('created_at', ascending: false);

      setState(() {
        _resources = response as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredResources = _selectedCategory == 'All'
        ? _resources
        : _resources.where((r) => r['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Resources'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'All',
                          isSelected: _selectedCategory == 'All',
                          onTap: () => setState(() => _selectedCategory = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: 'Lesson Plans',
                          isSelected: _selectedCategory == 'Lesson Plans',
                          onTap: () => setState(() => _selectedCategory = 'Lesson Plans'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: 'Handouts',
                          isSelected: _selectedCategory == 'Handouts',
                          onTap: () => setState(() => _selectedCategory = 'Handouts'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: 'Assessment',
                          isSelected: _selectedCategory == 'Assessment',
                          onTap: () => setState(() => _selectedCategory = 'Assessment'),
                        ),
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: 'Videos',
                          isSelected: _selectedCategory == 'Videos',
                          onTap: () => setState(() => _selectedCategory = 'Videos'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Resources List
                Expanded(
                  child: filteredResources.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              const Text(
                                'No resources available',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredResources.length,
                          itemBuilder: (context, index) {
                            final resource = filteredResources[index];
                            return _ResourceCard(resource: resource);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.sunsetBright.withValues(alpha: 0.2),
      checkmarkColor: AppColors.sunsetBright,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.sunsetBright : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
  });

  final Map<String, dynamic> resource;

  @override
  Widget build(BuildContext context) {
    final title = resource['title'] as String?;
    final description = resource['description'] as String?;
    final type = resource['type'] as String?;
    final category = resource['category'] as String?;
    final videoLink = resource['video_link'] as String?;
    final resourceLink = resource['resource_link'] as String?;
    final shareLink = resource['share_link'] as String?;
    final visibility = resource['visibility'] as String?;
    final createdAt = resource['created_at'] as String?;
    final instructorName = (resource['profiles'] as Map?)?['full_name'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (videoLink != null) {
            // Open video
          } else if (resourceLink != null) {
            // Open resource
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      type == 'video'
                          ? Icons.play_circle
                          : type == 'link'
                              ? Icons.link
                              : Icons.description,
                      color: AppColors.sunsetBright,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        if (instructorName != null)
                          Text(
                            'By $instructorName',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (description != null && description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category ?? 'General',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getVisibilityColor(visibility).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        visibility?.toUpperCase() ?? 'PRIVATE',
                        style: TextStyle(fontSize: 10, color: _getVisibilityColor(visibility)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    createdAt != null ? _formatDate(createdAt) : 'N/A',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              if (videoLink != null || resourceLink != null || shareLink != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (videoLink != null)
                      _LinkChip(icon: Icons.play_circle, label: 'Video', link: videoLink),
                    if (resourceLink != null)
                      _LinkChip(icon: Icons.link, label: 'Resource', link: resourceLink),
                    if (shareLink != null)
                      _LinkChip(icon: Icons.share, label: 'Share', link: shareLink),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getVisibilityColor(String? visibility) {
    switch (visibility?.toLowerCase()) {
      case 'public':
        return Colors.green;
      case 'selective':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.icon,
    required this.label,
    required this.link,
  });

  final IconData icon;
  final String label;
  final String link;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Open link
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.sunsetBright.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.sunsetBright),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.sunsetBright, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
