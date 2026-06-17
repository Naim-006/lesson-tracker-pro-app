import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PupilEnquiryScreen extends StatefulWidget {
  const PupilEnquiryScreen({super.key});

  @override
  State<PupilEnquiryScreen> createState() => _PupilEnquiryScreenState();
}

class _PupilEnquiryScreenState extends State<PupilEnquiryScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _enquiries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadEnquiries() async {
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('enquiries')
          .select('*, instructors!inner(full_name, business_name, hourly_rate, rating)')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);

      setState(() {
        _enquiries = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendEnquiry(String instructorId, String instructorName) async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await Supabase.instance.client.from('enquiries').insert({
        'pupil_id': user!.id,
        'instructor_id': instructorId,
        'message': _messageController.text.trim(),
        'status': 'pending',
      });

      _messageController.clear();
      Navigator.pop(context);
      _loadEnquiries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enquiry sent to $instructorName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send enquiry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enquiries'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enquiries.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
                  onRefresh: _loadEnquiries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _enquiries.length,
                    itemBuilder: (context, index) {
                      return _EnquiryCard(
                        enquiry: _enquiries[index],
                        onRefresh: _loadEnquiries,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewEnquiryDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Enquiries Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send enquiries to instructors to get started',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showNewEnquiryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Send New Enquiry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewEnquiryDialog() {
    showDialog(
      context: context,
      builder: (context) => _NewEnquiryDialog(
        onSend: _sendEnquiry,
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({
    required this.enquiry,
    required this.onRefresh,
  });

  final Map<String, dynamic> enquiry;
  final VoidCallback onRefresh;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'responded':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructor = enquiry['instructors'];
    final status = enquiry['status'];
    final createdAt = DateTime.parse(enquiry['created_at']);

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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructor['full_name'] ?? 'Instructor',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        instructor['business_name'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                enquiry['message'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (status == 'accepted')
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to book lesson
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Book Lesson'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NewEnquiryDialog extends StatefulWidget {
  const _NewEnquiryDialog({required this.onSend});

  final Function(String, String) onSend;

  @override
  State<_NewEnquiryDialog> createState() => _NewEnquiryDialogState();
}

class _NewEnquiryDialogState extends State<_NewEnquiryDialog> {
  final _messageController = TextEditingController();
  String? _selectedInstructorId;
  Map<String, dynamic>? _selectedInstructor;
  List<Map<String, dynamic>> _instructors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final response = await Supabase.instance.client
          .from('instructors')
          .select('*, profiles!inner(full_name)')
          .eq('is_verified', true)
          .order('rating', ascending: false)
          .limit(20);

      setState(() {
        _instructors = List<Map<String, dynamic>>.from(response);
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
    return AlertDialog(
      title: const Text('Send New Enquiry'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Instructor'),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedInstructorId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose an instructor',
                    ),
                    items: _instructors.map((instructor) {
                      return DropdownMenuItem<String>(
                        value: instructor['id'] as String,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(instructor['profiles']['full_name']),
                            Text(
                              '£${instructor['hourly_rate']}/hr',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedInstructorId = value;
                        _selectedInstructor = _instructors.firstWhere((i) => i['id'] == value);
                      });
                    },
                  ),
            const SizedBox(height: 16),
            const Text('Your Message'),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your enquiry message...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedInstructorId != null && _messageController.text.trim().isNotEmpty
              ? () {
                  widget.onSend(
                    _selectedInstructorId!,
                    _selectedInstructor!['profiles']['full_name'],
                  );
                }
              : null,
          child: const Text('Send'),
        ),
      ],
    );
  }
}
