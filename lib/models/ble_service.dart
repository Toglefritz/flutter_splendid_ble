class BleService {
  final String serviceUuid;
  final List<String> characteristicUuids;

  BleService({
    required this.serviceUuid,
    required this.characteristicUuids,
  });

  factory BleService.fromMap(Map<String, dynamic> map) {
    return BleService(
      serviceUuid: map['serviceUuid'] as String,
      characteristicUuids: List<String>.from(map['characteristicUuids'] as List),
    );
  }

  @override
  String toString() {
    return 'BleService(serviceUuid: $serviceUuid, characteristicUuids: $characteristicUuids)';
  }
}