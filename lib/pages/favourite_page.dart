import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'meal_details_pagw.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorite Meals'),
          backgroundColor: const Color(0xFF00667E),
        ),
        body: const Center(
          child: Text('Please log in to view your favorites.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Meals'),
        backgroundColor: const Color(0xFF00667E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorites found.'));
          }

          final favorites = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final doc = favorites[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? '',
                  width: 60,
                  fit: BoxFit.cover,
                ),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text(data['category'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('favorites')
                        .doc(doc.id)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from favorites'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
                onTap: () {
                  // Navigate to details page if desired
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MealDetailsPage(mealId: data['mealId']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
