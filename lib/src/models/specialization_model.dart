/// Healthcare specialization from `specializations` table.
class SpecializationModel {
  final int id;
  final String name;
  final String? description;

  const SpecializationModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
