import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class TeachingResourcesScreen extends ConsumerStatefulWidget {
  const TeachingResourcesScreen({super.key});

  @override
  ConsumerState<TeachingResourcesScreen> createState() => _TeachingResourcesScreenState();
}

class _TeachingResourcesScreenState extends ConsumerState<TeachingResourcesScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final resources = ref.watch(instructorTeachingResourcesProvider);
    final resourcesList = resources.value ?? [];
    final filteredResources = _selectedCategory == 'All'
        ? resourcesList
        : resourcesList.where((r) => r['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddResourceDialog(context),
          ),
        ],
      ),
      body: Column(
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
                          'No resources found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showAddResourceDialog(context),
                          child: const Text('Add Resource'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredResources.length,
                    itemBuilder: (context, index) {
                      final resourceMap = filteredResources[index];
                      final resource = _mapToResourceItem(resourceMap);
                      return _ResourceCard(
                        resource: resource,
                        resourceMap: resourceMap,
                        onEdit: () => _showEditResourceDialog(context, resource, resourceMap),
                        onDelete: () => _deleteResource(resource.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  ResourceItem _mapToResourceItem(Map<String, dynamic> map) {
    return ResourceItem(
      id: map['id'] as String,
      title: map['title'] as String,
      type: ResourceType.values.firstWhere((e) => e.name == map['type'] as String, orElse: () => ResourceType.document),
      category: map['category'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      videoLink: map['video_link'] as String?,
      resourceLink: map['resource_link'] as String?,
      shareLink: map['share_link'] as String?,
      visibility: ResourceVisibility.values.firstWhere((e) => e.name == map['visibility'] as String, orElse: () => ResourceVisibility.private),
      selectedPupilIds: (map['selected_pupil_ids'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> _resourceToMap(ResourceItem resource) {
    return {
      'title': resource.title,
      'type': resource.type.name,
      'category': resource.category,
      'description': resource.description,
      'video_link': resource.videoLink,
      'resource_link': resource.resourceLink,
      'share_link': resource.shareLink,
      'visibility': resource.visibility.name,
      'selected_pupil_ids': resource.selectedPupilIds,
    };
  }

  void _showAddResourceDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoLinkController = TextEditingController();
    final resourceLinkController = TextEditingController();
    final shareLinkController = TextEditingController();
    String category = 'Lesson Plans';
    ResourceType type = ResourceType.document;
    ResourceVisibility visibility = ResourceVisibility.private;
    final Set<String> selectedPupilIds = {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Resource'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ResourceType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ResourceType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const ['Lesson Plans', 'Handouts', 'Assessment', 'Videos']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: videoLinkController,
                    decoration: const InputDecoration(labelText: 'Video Link (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resourceLinkController,
                    decoration: const InputDecoration(labelText: 'Resource Link (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: shareLinkController,
                    decoration: const InputDecoration(labelText: 'Share Link (optional)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Visibility', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: ResourceVisibility.values.map((v) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<ResourceVisibility>(
                            value: v,
                            groupValue: visibility,
                            onChanged: (val) => setDialogState(() => visibility = val!),
                          ),
                          Text(v.name.toUpperCase()),
                          const SizedBox(width: 16),
                        ],
                      );
                    }).toList(),
                  ),
                  if (visibility == ResourceVisibility.selective) ...[
                    const SizedBox(height: 12),
                    const Text('Select Pupils', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _PupilSelector(
                        selectedPupilIds: selectedPupilIds,
                        onSelectionChanged: (ids) => setDialogState(() {
                          selectedPupilIds.clear();
                          selectedPupilIds.addAll(ids);
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  final resourceData = _resourceToMap(ResourceItem(
                    id: '',
                    title: titleController.text,
                    type: type,
                    category: category,
                    description: descriptionController.text,
                    createdAt: DateTime.now(),
                    videoLink: videoLinkController.text.isNotEmpty ? videoLinkController.text : null,
                    resourceLink: resourceLinkController.text.isNotEmpty ? resourceLinkController.text : null,
                    shareLink: shareLinkController.text.isNotEmpty ? shareLinkController.text : null,
                    visibility: visibility,
                    selectedPupilIds: selectedPupilIds.toList(),
                  ));
                  resourceData['instructor_id'] = user.id;

                  try {
                    await Supabase.instance.client.from('teaching_resources').insert(resourceData);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ref.invalidate(instructorTeachingResourcesProvider);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditResourceDialog(BuildContext context, ResourceItem resource, Map<String, dynamic> resourceMap) {
    final titleController = TextEditingController(text: resource.title);
    final descriptionController = TextEditingController(text: resource.description);
    final videoLinkController = TextEditingController(text: resource.videoLink ?? '');
    final resourceLinkController = TextEditingController(text: resource.resourceLink ?? '');
    final shareLinkController = TextEditingController(text: resource.shareLink ?? '');
    String category = resource.category;
    ResourceType type = resource.type;
    ResourceVisibility visibility = resource.visibility;
    final Set<String> selectedPupilIds = resource.selectedPupilIds.toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Resource'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ResourceType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ResourceType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const ['Lesson Plans', 'Handouts', 'Assessment', 'Videos']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: videoLinkController,
                    decoration: const InputDecoration(labelText: 'Video Link (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resourceLinkController,
                    decoration: const InputDecoration(labelText: 'Resource Link (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: shareLinkController,
                    decoration: const InputDecoration(labelText: 'Share Link (optional)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Visibility', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: ResourceVisibility.values.map((v) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<ResourceVisibility>(
                            value: v,
                            groupValue: visibility,
                            onChanged: (val) => setDialogState(() => visibility = val!),
                          ),
                          Text(v.name.toUpperCase()),
                          const SizedBox(width: 16),
                        ],
                      );
                    }).toList(),
                  ),
                  if (visibility == ResourceVisibility.selective) ...[
                    const SizedBox(height: 12),
                    const Text('Select Pupils', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _PupilSelector(
                        selectedPupilIds: selectedPupilIds,
                        onSelectionChanged: (ids) => setDialogState(() {
                          selectedPupilIds.clear();
                          selectedPupilIds.addAll(ids);
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final updatedResource = ResourceItem(
                  id: resource.id,
                  title: titleController.text,
                  type: type,
                  category: category,
                  description: descriptionController.text,
                  createdAt: resource.createdAt,
                  videoLink: videoLinkController.text.isNotEmpty ? videoLinkController.text : null,
                  resourceLink: resourceLinkController.text.isNotEmpty ? resourceLinkController.text : null,
                  shareLink: shareLinkController.text.isNotEmpty ? shareLinkController.text : null,
                  visibility: visibility,
                  selectedPupilIds: selectedPupilIds.toList(),
                );

                try {
                  await Supabase.instance.client
                      .from('teaching_resources')
                      .update(_resourceToMap(updatedResource))
                      .eq('id', resource.id);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(instructorTeachingResourcesProvider);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteResource(String id) async {
    try {
      await Supabase.instance.client.from('teaching_resources').delete().eq('id', id);
      if (mounted) {
        ref.invalidate(instructorTeachingResourcesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

class _PupilSelector extends ConsumerWidget {
  const _PupilSelector({
    required this.selectedPupilIds,
    required this.onSelectionChanged,
  });

  final Set<String> selectedPupilIds;
  final void Function(Set<String>) onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pupils = ref.watch(instructorPupilsProvider);
    final pupilsList = pupils.value ?? [];

    if (pupilsList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No pupils available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      itemCount: pupilsList.length,
      itemBuilder: (context, index) {
        final link = pupilsList[index];
        final pupilData = link['pupils'];
        final profile = pupilData?['profiles'];
        final pupilId = pupilData['id'];
        final pupilName = profile?['full_name'] ?? 'Unknown';
        final isSelected = selectedPupilIds.contains(pupilId);
        return CheckboxListTile(
          title: Text(pupilName),
          value: isSelected,
          onChanged: (checked) {
            final newSelection = Set<String>.from(selectedPupilIds);
            if (checked == true) {
              newSelection.add(pupilId);
            } else {
              newSelection.remove(pupilId);
            }
            onSelectionChanged(newSelection);
          },
        );
      },
    );
  }
}

class ResourceItem {
  String id;
  String title;
  ResourceType type;
  String category;
  String description;
  DateTime createdAt;
  String? videoLink;
  String? resourceLink;
  String? shareLink;
  ResourceVisibility visibility;
  List<String> selectedPupilIds;

  ResourceItem({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.description,
    required this.createdAt,
    this.videoLink,
    this.resourceLink,
    this.shareLink,
    this.visibility = ResourceVisibility.private,
    this.selectedPupilIds = const [],
  });
}

enum ResourceType { document, video, link }

enum ResourceVisibility { private, public, selective }

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
    required this.resourceMap,
    required this.onEdit,
    required this.onDelete,
  });

  final ResourceItem resource;
  final Map<String, dynamic> resourceMap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: InkWell(
          onTap: () async {
            final link = resource.videoLink ?? resource.resourceLink ?? resource.shareLink;
            if (link != null) {
              final uri = Uri.tryParse(link);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
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
                      resource.type == ResourceType.document
                          ? Icons.description
                          : resource.type == ResourceType.video
                              ? Icons.play_circle
                              : Icons.link,
                      color: AppColors.sunsetBright,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resource.description,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showMenu(context, onEdit, onDelete),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      resource.category,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getVisibilityColor(resource.visibility).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      resource.visibility.name.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: _getVisibilityColor(resource.visibility)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (resource.visibility == ResourceVisibility.selective)
                    Text(
                      '${resource.selectedPupilIds.length} pupils',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  const Spacer(),
                  Text(
                    '${DateTime.now().difference(resource.createdAt).inDays}d ago',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              if (resource.videoLink != null || resource.resourceLink != null || resource.shareLink != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (resource.videoLink != null)
                      _LinkChip(icon: Icons.play_circle, label: 'Video', link: resource.videoLink!),
                    if (resource.resourceLink != null)
                      _LinkChip(icon: Icons.link, label: 'Resource', link: resource.resourceLink!),
                    if (resource.shareLink != null)
                      _LinkChip(icon: Icons.share, label: 'Share', link: resource.shareLink!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getVisibilityColor(ResourceVisibility visibility) {
    switch (visibility) {
      case ResourceVisibility.private:
        return Colors.orange;
      case ResourceVisibility.public:
        return Colors.green;
      case ResourceVisibility.selective:
        return Colors.blue;
    }
  }

  void _showMenu(BuildContext context, VoidCallback onEdit, VoidCallback onDelete) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          onTap: onEdit,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
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
      onTap: () async {
        final uri = Uri.tryParse(link);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
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
