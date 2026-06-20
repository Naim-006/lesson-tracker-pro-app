import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(instructorVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showVehicleDialog(context, ref),
          ),
        ],
      ),
      body: vehicles.value == null || vehicles.value!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No vehicles added yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showVehicleDialog(context, ref),
                    child: const Text('Add Vehicle'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.value!.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles.value![index];
                return _VehicleCard(
                  vehicle: vehicle,
                  onEdit: () => _showVehicleDialog(context, ref, vehicle: vehicle),
                  onDelete: () => _deleteVehicle(context, ref, vehicle['id']),
                );
              },
            ),
    );
  }

  void _showVehicleDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? vehicle}) {
    final makeController = TextEditingController(text: vehicle?['make'] ?? '');
    final modelController = TextEditingController(text: vehicle?['model'] ?? '');
    final regController = TextEditingController(text: vehicle?['plate'] ?? '');
    final yearController = TextEditingController(text: vehicle?['year']?.toString() ?? '');
    final colorController = TextEditingController(text: vehicle?['color'] ?? '');
    final notesController = TextEditingController(text: vehicle?['notes'] ?? '');
    bool isPrimary = vehicle?['is_primary'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: makeController,
                  decoration: const InputDecoration(labelText: 'Make', prefixIcon: Icon(Icons.directions_car)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Model', prefixIcon: Icon(Icons.info)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regController,
                  decoration: const InputDecoration(labelText: 'Registration Plate', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Year', prefixIcon: Icon(Icons.calendar_today)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.palette)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.note)),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Primary Vehicle'),
                  subtitle: const Text('Set as default for lessons'),
                  value: isPrimary,
                  onChanged: (v) => setState(() => isPrimary = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (makeController.text.isEmpty || modelController.text.isEmpty || regController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in required fields')),
                  );
                  return;
                }

                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;

                final vehicleData = {
                  'instructor_id': user.id,
                  'make': makeController.text,
                  'model': modelController.text,
                  'plate': regController.text,
                  'year': int.tryParse(yearController.text),
                  'color': colorController.text,
                  'notes': notesController.text,
                  'is_primary': isPrimary,
                };

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                try {
                  if (vehicle == null) {
                    await Supabase.instance.client.from('vehicles').insert(vehicleData);
                  } else {
                    await Supabase.instance.client
                        .from('vehicles')
                        .update(vehicleData)
                        .eq('id', vehicle['id']);
                  }
                  if (!mounted) return;
                  navigator.pop();
                  ref.invalidate(instructorVehiclesProvider);
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVehicle(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              try {
                await Supabase.instance.client.from('vehicles').delete().eq('id', id);
                if (!mounted) return;
                navigator.pop();
                ref.invalidate(instructorVehiclesProvider);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                  child: Icon(Icons.directions_car, color: AppColors.sunsetBright),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle['make']} ${vehicle['model']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        vehicle['plate'],
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (vehicle['is_primary'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(fontSize: 11, color: AppColors.sunsetBright, fontWeight: FontWeight.bold),
                    ),
                  ),
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
              ],
            ),
            if (vehicle['year'] != null || vehicle['color'] != null) ...[
              const SizedBox(height: 12),
              Text(
                '${vehicle['year'] != null ? 'Year: ${vehicle['year']}' : ''}${vehicle['year'] != null && vehicle['color'] != null ? ' • ' : ''}${vehicle['color'] != null ? 'Color: ${vehicle['color']}' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (vehicle['notes'] != null && vehicle['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                vehicle['notes'].toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
