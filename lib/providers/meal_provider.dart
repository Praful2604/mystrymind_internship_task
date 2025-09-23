import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/meal.dart';

class MealProvider with ChangeNotifier {
  List<Meal> meals = [];
  bool isLoading = false;

  Timer? _debounce;

  void searchMeals(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      meals = [];
      notifyListeners();
      return;
    }
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.themealdb.com/api/json/v1/1/search.php?s=$query'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          meals = List<Meal>.from(
            data['meals'].map((meal) => Meal.fromJson(meal)),
          );
        } else {
          meals = [];
        }
      } else {
        meals = [];
      }
    } catch (e) {
      meals = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
