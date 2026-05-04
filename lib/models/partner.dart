class Partner {
  final String id;
  final String name;
  final double percentage;
  final double withdrawn;

  Partner({
    required this.id,
    required this.name,
    required this.percentage,
    this.withdrawn = 0,
  });

  factory Partner.fromMap(Map<String, dynamic> data, String id) {
    return Partner(
      id: id,
      name: data['name'] ?? '',
      percentage: (data['percentage'] ?? 0).toDouble(),
      withdrawn: (data['withdrawn'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'percentage': percentage,
        'withdrawn': withdrawn,
      };
}
