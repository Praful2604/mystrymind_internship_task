import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MealDetailsPage extends StatefulWidget {
  final String mealId;

  const MealDetailsPage({super.key, required this.mealId});

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  Map<String, dynamic>? mealData;
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    fetchMealDetails();
    checkIfFavorite();
  }

  Future<void> fetchMealDetails() async {
    final String url =
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.mealId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          setState(() {
            mealData = data['meals'][0];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isFavorite = false;
      });
      return;
    }

    final String docId = '${user.uid}_${widget.mealId}';
    final docSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(docId)
        .get();
    setState(() {
      isFavorite = docSnapshot.exists;
    });
  }

  Future<void> saveToFavorites() async {
    try {
      if (mealData == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle case when user is not logged in
        return;
      }

      final String docId = '${user.uid}_${widget.mealId}';
      final docRef =
          FirebaseFirestore.instance.collection('favorites').doc(docId);

      await docRef.set({
        'mealId': widget.mealId,
        'name': mealData!['strMeal'],
        'category': mealData!['strCategory'],
        'area': mealData!['strArea'],
        'instructions': mealData!['strInstructions'],
        'imageUrl': mealData!['strMealThumb'],
        'userId': user.uid, // Add this line
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        isFavorite = true;
      });
    } catch (e) {
      print('Error saving to favorites: $e');
    }
  }

  Future<void> removeFromFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final String docId = '${user.uid}_${widget.mealId}';
    final docRef =
        FirebaseFirestore.instance.collection('favorites').doc(docId);
    await docRef.delete();

    setState(() {
      isFavorite = false;
    });
  }

  List<String> extractIngredients() {
    final List<String> ingredients = [];
    if (mealData == null) return ingredients;

    for (int i = 1; i <= 20; i++) {
      final ingredient = mealData?['strIngredient$i'];
      final measure = mealData?['strMeasure$i'];

      if (ingredient != null &&
          ingredient.isNotEmpty &&
          ingredient != '' &&
          measure != null &&
          measure.isNotEmpty) {
        ingredients.add('$ingredient - $measure');
      }
    }

    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (mealData == null) {
      return const Scaffold(
        body: Center(child: Text('Meal not found')),
      );
    }

    final ingredients = extractIngredients();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mealData?['strMeal'] ?? 'Meal Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00667E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mealData?['strMealThumb'] ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              mealData?['strMeal'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(
                  label: Text(mealData?['strCategory'] ?? ''),
                  backgroundColor: Colors.cyan.shade100,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(mealData?['strArea'] ?? ''),
                  backgroundColor: Colors.cyan.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              mealData?['strInstructions'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            ...ingredients.map((ing) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $ing', style: const TextStyle(fontSize: 16)),
                )),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isFavorite) {
                    await removeFromFavorites();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from favorites'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    await saveToFavorites();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved to favorites'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                label: Text(
                  isFavorite ? 'Remove from Favorites' : 'Save to Favorites',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00667E),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
