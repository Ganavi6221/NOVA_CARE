import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedType = 'hospital';
  String searchQuery = '';
  Set<String> favoriteIds = {};
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> categories = {
    'hospital': 'Hospital',
    'blood_bank': 'Blood Bank',
    'women_help_centre': 'Women Help Centre',
    'ambulance': 'Ambulance Services',
  };

  final Map<String, IconData> _icons = {
    'hospital': Icons.local_hospital,
    'blood_bank': Icons.bloodtype,
    'women_help_centre': Icons.female,
    'ambulance': Icons.local_shipping,
  };

  // Toggle favorite (stored in memory only for web)
  void _toggleFavorite(String id) {
    setState(() {
      if (favoriteIds.contains(id)) {
        favoriteIds.remove(id);
      } else {
        favoriteIds.add(id);
      }
    });
  }

  // Show details bottom sheet
  void _showDetailsSheet(Map<String, dynamic> service, String serviceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final name = (service['Name'] ?? service['name'] ?? 'No Name').toString();
          final contact = (service['Contact'] ?? service['contact'] ?? '').toString();
          final area = (service['Area'] ?? service['area'] ?? '').toString();
          final type = (service['Type'] ?? service['type'] ?? '').toString();

          return Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red.shade700,
                      child: Icon(_icons[selectedType], color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Type badge
                if (type.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Contact info
                _buildInfoTile(Icons.phone, 'Contact', contact),
                _buildInfoTile(Icons.location_on, 'Location', area),
                
                const SizedBox(height: 30),

                // Info message for web
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Copy the contact number to call',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pull to refresh
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('emergency_services')
        .doc(
          selectedType == 'hospital'
              ? 'Hospital'
              : selectedType == 'ambulance'
                  ? 'Ambulance'
                  : selectedType == 'blood_bank'
                      ? 'Blood_Bank'
                      : 'Women_Help_Centre',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Crisis'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: query.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerLoading();
                      }

                      final raw = snapshot.data?.data();
                      if (raw == null) {
                        return _buildEmptyState();
                      }

                      final data = raw as Map<String, dynamic>;

                      if (data.isEmpty) {
                        return _buildEmptyState();
                      }

                      final docs = [data];
                      
                      // Filter by search query
                      final filteredDocs = docs.where((doc) {
                        if (searchQuery.isEmpty) return true;
                        final name = (doc['Name'] ?? doc['name'] ?? '').toString().toLowerCase();
                        final area = (doc['Area'] ?? doc['area'] ?? '').toString().toLowerCase();
                        final contact = (doc['Contact'] ?? doc['contact'] ?? '').toString().toLowerCase();
                        return name.contains(searchQuery) || 
                               area.contains(searchQuery) || 
                               contact.contains(searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return _buildNoResultsState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final itemData = filteredDocs[index];
                          final serviceId = '${selectedType}_$index';

                          final name = (itemData['Name'] ?? itemData['name'] ?? 'No Name').toString();
                          final contact = (itemData['Contact'] ?? itemData['contact'] ?? '').toString();
                          final area = (itemData['Area'] ?? itemData['area'] ?? '').toString();
                          final isFavorite = favoriteIds.contains(serviceId);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showDetailsSheet(itemData, serviceId),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Icon
                                    CircleAvatar(
                                      backgroundColor: Colors.red.shade700,
                                      child: Icon(
                                        _icons[selectedType] ?? Icons.help_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (contact.isNotEmpty || area.isNotEmpty)
                                            Text(
                                              [contact, area].where((e) => e.isNotEmpty).join(' • '),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Favorite button only (no call button for web)
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => _toggleFavorite(serviceId),
                                      tooltip: 'Favorite',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Bottom category bar
              SafeArea(
                top: false,
                child: Container(
                  color: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Row(
                    children: categories.keys.map((key) {
                      final label = categories[key]!;
                      final isSel = selectedType == key;

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedType = key;
                              searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _icons[key] ?? Icons.help_outline,
                                  color: isSel ? Colors.red.shade700 : Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shimmer loading effect
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'No services found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // No search results state
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}