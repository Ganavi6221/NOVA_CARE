import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Crisis'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('emergency_services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hospital entries found'));
          }

          final docs = snapshot.data!.docs;
          debugPrint('Hospital docs count: ${docs.length}');

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
              debugPrint('Doc id=${doc.id} keys=${data.keys.toList()} values=${data}');

              String safe(dynamic v) => v == null ? '' : v.toString();

              final titleRaw = data['name'] ?? data['Name'] ?? data['hospital_name'];
              final contactRaw = data['Contact'] ?? data['contact'] ?? data['phone'] ?? data['Phone'];

              final title = safe(titleRaw).isEmpty ? 'No Name' : safe(titleRaw);
              final contact = safe(contactRaw).isEmpty ? 'No phone' : safe(contactRaw);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(contact),
                  onTap: () {
                    // Later: call functionality
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
