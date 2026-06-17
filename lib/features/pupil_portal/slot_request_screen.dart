import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SlotRequestScreen extends StatefulWidget {
  const SlotRequestScreen({super.key});

  @override
  State<SlotRequestScreen> createState() => _SlotRequestScreenState();
}

class _SlotRequestScreenState extends State<SlotRequestScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _availableSlots = [];
  Map<String, dynamic>? _linkedInstructor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (user == null) return;

    try {
      // Get linked instructor
      final linkResponse = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id, instructors!inner(profiles!inner(full_name, business_name))')
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
      _linkedInstructor = linkResponse['instructors'];

      // Load available slots
      final slotsResponse = await Supabase.instance.client
          .from('open_slots')
          .select('*')
          .eq('instructor_id', instructorId)
          .eq('is_booked', false)
          .gte('date', DateTime.now().toIso8601String())
          .order('date', ascending: true);

      setState(() {
        _availableSlots = List<Map<String, dynamic>>.from(slotsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSlot(String slotId) async {
    try {
      await Supabase.instance.client.from('open_slots').update({
        'is_booked': true,
        'booked_by': user!.id,
      }).eq('id', slotId);

      // Create lesson record
      final slot = _availableSlots.firstWhere((s) => s['id'] == slotId);
      await Supabase.instance.client.from('lessons').insert({
        'instructor_id': _linkedInstructor!['id'],
        'pupil_id': user!.id,
        'date': slot['date'],
        'time': slot['start_time'],
        'duration': slot['duration'],
        'pickup_location': slot['location'],
        'status': 'scheduled',
      });

      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot requested successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request slot: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Slots'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _linkedInstructor == null
              ? _buildNoInstructorView()
              : _availableSlots.isEmpty
                  ? _buildNoSlotsView()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableSlots.length,
                        itemBuilder: (context, index) {
                          return _SlotCard(
                            slot: _availableSlots[index],
                            onRequest: () => _requestSlot(_availableSlots[index]['id']),
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
              'Link with an instructor to request slots',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to find tutors
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Find an Instructor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSlotsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Available Slots',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your instructor hasn\'t posted any available slots yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to send message to instructor
              },
              icon: const Icon(Icons.message),
              label: const Text('Contact Instructor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.onRequest,
  });

  final Map<String, dynamic> slot;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(slot['date']);
    final duration = slot['duration'];

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
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(date),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${slot['start_time']} - $duration minutes',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (slot['location'] != null && slot['location'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      slot['location'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Request Slot',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }
}
