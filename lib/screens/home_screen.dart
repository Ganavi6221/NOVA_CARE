import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  String selectedType = 'hospital';

  
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
                      : selectedType == 'women_help_centre'
                          ? 'Women_Help_Centre'  
                          : 'Hospital',  
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Crisis'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
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
                  const SizedBox(height: 12),
                  
                  const SizedBox(height: 12),
                  
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: query.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

                        
                        List<dynamic> servicesList = [];
                        try {
                          if (data.containsKey('services')) {
                            servicesList = data['services'] as List<dynamic>? ?? [];
                          } else if (data.containsKey('Services')) {
                            servicesList = data['Services'] as List<dynamic>? ?? [];
                          } else if (data.containsKey('data')) {
                            servicesList = data['data'] as List<dynamic>? ?? [];
                          }
                        } catch (e) {
                        
                          servicesList = [];
                        }

                        
                        final docs = servicesList.map((e) => e as Map<String, dynamic>? ?? {}).toList();

                        
                        final filtered = docs;

                        if (filtered.isEmpty) {
                          return const Center(child: Text('No services found'));
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final data = filtered[index];  // Simplified access

                            final name = (data['name'] ?? data['Name'] ?? 'No Name').toString();
                            final contact = (data['contact'] ?? '').toString();
                            final area = (data['area'] ?? data['Area'] ?? data['city'] ?? data['City'] ?? '').toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(name),
                                subtitle: Text([contact, area].where((e) => e.isNotEmpty).join(' • ')),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
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
                              onTap: () => setState(() => selectedType = key),
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
          );
        },
      ),
    );
  }
}