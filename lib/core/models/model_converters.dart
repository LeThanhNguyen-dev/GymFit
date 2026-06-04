DateTime? dateTimeFromJson(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.parse(value.toString());
}

String? dateToJson(DateTime? value) =>
    value?.toIso8601String().split('T').first;

String? dateTimeToJson(DateTime? value) => value?.toIso8601String();

double? doubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}

int? intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

Map<String, dynamic> mapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<String> stringListFromJson(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return <String>[];
}

List<Map<String, dynamic>> mapListFromJson(Object? value) {
  if (value is List) {
    return value.map((item) => mapFromJson(item)).toList();
  }
  return <Map<String, dynamic>>[];
}
