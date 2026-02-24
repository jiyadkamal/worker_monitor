class Worker {
  final String? id;
  final String name;
  final String email;
  final String gender;
  final int age;
  final double weight;
  final double height;
  final double bmi;

  Worker({
    this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.bmi,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      age: (json['age'] is int) ? json['age'] : (json['age'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
    };
  }
}
