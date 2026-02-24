class MonitoringRecord {
  final String? id;
  final String workerId;
  final String? workerName;
  final double windSpeed;
  final double blackBallTemp;
  final double ambientTemp;
  final double humidity;
  final String activityIntensity;
  final String pulse;
  final String clothing;
  final double workDuration;
  final double heatStressIndex;
  final String riskLevel;
  final DateTime? createdAt;

  MonitoringRecord({
    this.id,
    required this.workerId,
    this.workerName,
    required this.windSpeed,
    required this.blackBallTemp,
    required this.ambientTemp,
    required this.humidity,
    required this.activityIntensity,
    required this.pulse,
    required this.clothing,
    required this.workDuration,
    required this.heatStressIndex,
    required this.riskLevel,
    this.createdAt,
  });

  factory MonitoringRecord.fromJson(Map<String, dynamic> json) {
    // workerId can be an object (populated) or a string
    String wId = '';
    String? wName;
    if (json['workerId'] is Map) {
      wId = json['workerId']['_id'] ?? '';
      wName = json['workerId']['name'];
    } else {
      wId = json['workerId'] ?? '';
    }

    return MonitoringRecord(
      id: json['_id'] ?? json['id'],
      workerId: wId,
      workerName: wName,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      blackBallTemp: (json['blackBallTemp'] as num).toDouble(),
      ambientTemp: (json['ambientTemp'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      activityIntensity: json['activityIntensity'] ?? '',
      pulse: json['pulse'] ?? '',
      clothing: json['clothing'] ?? '',
      workDuration: (json['workDuration'] as num).toDouble(),
      heatStressIndex: (json['heatStressIndex'] as num).toDouble(),
      riskLevel: json['riskLevel'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'windSpeed': windSpeed,
      'blackBallTemp': blackBallTemp,
      'ambientTemp': ambientTemp,
      'humidity': humidity,
      'activityIntensity': activityIntensity,
      'pulse': pulse,
      'clothing': clothing,
      'workDuration': workDuration,
      'heatStressIndex': heatStressIndex,
      'riskLevel': riskLevel,
    };
  }
}
