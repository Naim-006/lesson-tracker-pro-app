import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearbyTutorsScreen extends StatefulWidget {
  const NearbyTutorsScreen({super.key});

  @override
  State<NearbyTutorsScreen> createState() => _NearbyTutorsScreenState();
}

class _NearbyTutorsScreenState extends State<NearbyTutorsScreen> {
  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _filteredInstructors = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final response = await Supabase.instance.client
          .from('instructors')
          .select('*, profiles!inner(full_name, email, avatar_url)')
          .eq('is_verified', true)
          .order('rating', ascending: false);

      setState(() {
        _instructors = List<Map<String, dynamic>>.from(response);
        _filteredInstructors = _instructors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterInstructors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInstructors = _instructors;
      } else {
        _filteredInstructors = _instructors.where((instructor) {
          final name = instructor['profiles']['full_name'].toString().toLowerCase();
          final business = instructor['business_name'].toString().toLowerCase();
          return name.contains(query.toLowerCase()) || business.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'all') {
        _filteredInstructors = _instructors;
      } else if (filter == 'rating') {
        _filteredInstructors = List.from(_instructors)..sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
      } else if (filter == 'price_low') {
        _filteredInstructors = List.from(_instructors)..sort((a, b) => (a['hourly_rate'] as num).compareTo(b['hourly_rate'] as num));
      } else if (filter == 'price_high') {
        _filteredInstructors = List.from(_instructors)..sort((a, b) => (b['hourly_rate'] as num).compareTo(a['hourly_rate'] as num));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Instructors'),
        backgroundColor: Colors.orange,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search instructors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterInstructors('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterInstructors,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: _filteredInstructors.isEmpty
                      ? _buildEmptyView()
                      : RefreshIndicator(
                          onRefresh: _loadInstructors,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredInstructors.length,
                            itemBuilder: (context, index) {
                              return _InstructorCard(
                                instructor: _filteredInstructors[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: _selectedFilter == 'all',
              onTap: () => _applyFilter('all'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Top Rated',
              isSelected: _selectedFilter == 'rating',
              onTap: () => _applyFilter('rating'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Price: Low to High',
              isSelected: _selectedFilter == 'price_low',
              onTap: () => _applyFilter('price_low'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Price: High to Low',
              isSelected: _selectedFilter == 'price_high',
              onTap: () => _applyFilter('price_high'),
            ),
          ],
        ),
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
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Instructors Found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({required this.instructor});

  final Map<String, dynamic> instructor;

  @override
  Widget build(BuildContext context) {
    final profile = instructor['profiles'];
    final rating = instructor['rating'] ?? 0.0;
    final reviewCount = instructor['review_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? Icon(
                          Icons.person,
                          color: Colors.orange,
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['full_name'] ?? 'Instructor',
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '($reviewCount reviews)',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '£${instructor['hourly_rate']}/hr',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            if (instructor['bio'] != null && instructor['bio'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                instructor['bio'],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            if (instructor['languages'] != null && instructor['languages'].isNotEmpty) ...[
              Wrap(
                spacing: 8,
                children: (instructor['languages'] as List).map((lang) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lang,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to instructor profile
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // Send enquiry
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Send Enquiry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
