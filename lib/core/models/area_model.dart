class AreaModel {
  final int id;
  final String areaName;
  final int cityId;

  AreaModel({
    required this.id,
    required this.areaName,
    required this.cityId,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as int,
      areaName: json['area_name'] as String,
      cityId: json['city_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_name': areaName,
      'city_id': cityId,
    };
  }

  @override
  String toString() {
    return 'AreaModel(id: $id, areaName: $areaName, cityId: $cityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaModel &&
        other.id == id &&
        other.areaName == areaName &&
        other.cityId == cityId;
  }

  @override
  int get hashCode => id.hashCode ^ areaName.hashCode ^ cityId.hashCode;
}