import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Default selected type is 'hospital'
  String selectedType = 'hospital';

  // Simple mapping for the UI chips. Keys are normalized (lowercase, no spaces)
  final Map<String, String> categories = {
    'hospital': 'Hospital',
    'ambulance': 'Ambulance',
    'blood_bank': 'Blood Bank',
  };

  @override
  Widget build(BuildContext context) {
    // Fetch all docs and rely on client-side filtering below so we tolerate
    // different field names/casing in existing Firestore documents.
    final query = FirebaseFirestore.instance.collection('emergency_services');

    // Helper to find a field value by matching keys loosely (trim + lowercase)
    dynamic findField(Map<String, dynamic> m, String target) {
      for (final k in m.keys) {
        try {
          if (k.toString().trim().toLowerCase() == target) return m[k];
        } catch (_) {}
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Crisis'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Category selector using ChoiceChip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: categories.keys.map((key) {
                return ChoiceChip(
                  label: Text(categories[key]!),
                  selected: selectedType == key,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  onSelected: (sel) {
                    if (sel) {
                      setState(() => selectedType = key);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Quick debug info: fetch all documents once and show total/types
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('emergency_services').get(),
              builder: (context, allSnap) {
                if (allSnap.hasError) return const SizedBox.shrink();
                if (allSnap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 24, child: Center(child: SizedBox.shrink()));
                }

                final allDocs = allSnap.data?.docs ?? [];
                // Collect normalized type values from both 'type' and 'Type'
                final types = allDocs.map((d) {
                  final m = d.data() as Map<String, dynamic>? ?? {};
                  final raw = (m['type'] ?? m['Type'] ?? '').toString().trim();
                  return raw.isEmpty ? '<none>' : raw.toLowerCase();
                }).toSet().where((e) => e.isNotEmpty).join(', ');

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selected: $selectedType • total: ${allDocs.length} • types: ${types.isEmpty ? '<none>' : types}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Expanded StreamBuilder for the filtered list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final rawType = (data['type'] ?? data['Type'] ?? '').toString().trim().toLowerCase();
                  return rawType == selectedType;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No services found'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    

                    String safe(dynamic v) => v == null ? '' : v.toString();

                    final nameRaw = data['name'] ?? data['Name'] ?? data['Name '] ?? findField(data, 'name') ?? '';
                    final contactRaw = data['contact'] ?? data['Contact'] ?? data['Contact '] ?? findField(data, 'contact') ?? '';
                    final areaRaw = data['area'] ?? data['Area'] ?? data['City'] ?? data['city'] ?? findField(data, 'city') ?? findField(data, 'area') ?? '';

                    final name = safe(nameRaw).isEmpty ? 'No Name' : safe(nameRaw);
                    final contact = safe(contactRaw);
                    final area = safe(areaRaw);

                    // Build a friendly subtitle: prefer contact, then area; if both missing show raw data
                    String subtitleText;
                    if (contact.isEmpty && area.isEmpty) {
                      subtitleText = data.toString();
                    } else if (contact.isEmpty) {
                      subtitleText = area;
                    } else if (area.isEmpty) {
                      subtitleText = contact;
                    } else {
                      subtitleText = '$contact • $area';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(subtitleText),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
