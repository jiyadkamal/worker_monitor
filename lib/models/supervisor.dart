class Supervisor {
  final String id;
  final String name;
  final String email;

  Supervisor({required this.id, required this.name, required this.email});

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
