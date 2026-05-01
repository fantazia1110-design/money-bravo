import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class Account {
  final String id;
  final String name;
  final String currency;
  final String? secondaryCurrency;
  final String icon;
  String? imagePath;
  final List<String> colors; // gradient hex colors
  double balance; // computed from transactions

  Account({
    required this.id,
    required this.name,
    required this.currency,
    this.secondaryCurrency,
    required this.icon,
    this.imagePath,
    required this.colors,
    this.balance = 0,
  });

  factory Account.fromMap(Map<String, dynamic> data, String id) {
    return Account(
      id: id,
      name: data['name'] ?? '',
      currency: data['currency'] ?? 'EGP',
      secondaryCurrency: data['secondaryCurrency'],
      icon: data['icon'] ?? '💰',
      imagePath: data['imagePath'],
      colors: List<String>.from(data['colors'] ?? ['#6D28D9', '#4C1D95']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'currency': currency,
        'secondaryCurrency': secondaryCurrency,
        'icon': icon,
        'imagePath': imagePath,
        'colors': colors,
      };

  Account copyWith({double? balance}) => Account(
        id: id,
        name: name,
        currency: currency,
        secondaryCurrency: secondaryCurrency ?? secondaryCurrency,
        icon: icon,
        imagePath: imagePath ?? imagePath,
        colors: colors,
        balance: balance ?? this.balance,
      );

  Color get startColor => Color(hexToColorInt(colors[0]));
  Color get endColor => Color(hexToColorInt(colors[1]));
}
