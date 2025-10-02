class CityModel {
  final int id;
  final String name;
  final int stateId;

  CityModel({
    required this.id,
    required this.name,
    required this.stateId,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      stateId: json['state_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state_id': stateId,
    };
  }

  @override
  String toString() {
    return 'CityModel(id: $id, name: $name, stateId: $stateId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityModel &&
        other.id == id &&
        other.name == name &&
        other.stateId == stateId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ stateId.hashCode;
}