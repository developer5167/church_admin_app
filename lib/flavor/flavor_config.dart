import 'package:flutter/material.dart';
import 'app_flavor.dart';
import 'flavor_values.dart';

class FlavorConfig {
  final AppFlavor flavor;
  final FlavorValues values;

  static FlavorConfig? _instance;

  FlavorConfig._internal(this.flavor, this.values);

  static void init({
    required AppFlavor flavor,
    required FlavorValues values,
  }) {
    _instance = FlavorConfig._internal(flavor, values);
  }

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception("FlavorConfig not initialized");
    }
    return _instance!;
  }
}
