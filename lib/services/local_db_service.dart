import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database_helper.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class LocalDbService {
  static const _storage = FlutterSecureStorage();
  static const _supervisorIdKey = 'supervisor_id';

  // ── Helpers ───────────────────────────────────────────────
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ── Auth ──────────────────────────────────────────────────
  static Future<int?> getSupervisorId() async {
    final id = await _storage.read(key: _supervisorIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  static Future<void> _saveSupervisorId(int id) async {
    await _storage.write(key: _supervisorIdKey, value: id.toString());
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _supervisorIdKey);
  }

  static Future<bool> hasSession() async {
    return await getSupervisorId() != null;
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final db = await DatabaseHelper.instance.database;

    // Check if email already exists
    final existing =
        await db.query('supervisors', where: 'email = ?', whereArgs: [email]);
    if (existing.isNotEmpty) {
      throw AuthException('Email already registered');
    }

    final id = await db.insert('supervisors', {
      'name': name,
      'email': email,
      'password': _hashPassword(password),
    });

    await _saveSupervisorId(id);
    return {
      'supervisor': {'id': id, 'name': name, 'email': email},
    };
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'supervisors',
      where: 'email = ? AND password = ?',
      whereArgs: [email, _hashPassword(password)],
    );

    if (results.isEmpty) {
      throw AuthException('Invalid email or password');
    }

    final sup = results.first;
    final id = sup['id'] as int;
    await _saveSupervisorId(id);
    return {
      'supervisor': {
        'id': id,
        'name': sup['name'],
        'email': sup['email'],
      },
    };
  }

  // ── Workers ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getWorkers(
      {String? search}) async {
    final db = await DatabaseHelper.instance.database;
    final supId = await getSupervisorId();
    if (supId == null) throw AuthException('Not authenticated');

    String whereClause = 'supervisorId = ?';
    List<dynamic> whereArgs = [supId];

    if (search != null && search.isNotEmpty) {
      whereClause += ' AND name LIKE ?';
      whereArgs.add('%$search%');
    }

    final results = await db.query(
      'workers',
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Convert SQLite rows to match the JSON format the app expects
    return results.map((row) {
      return {
        '_id': row['id'].toString(),
        'name': row['name'],
        'email': row['email'],
        'gender': row['gender'],
        'age': row['age'],
        'weight': row['weight'],
        'height': row['height'],
        'bmi': row['bmi'],
        'photoUrl': row['photoPath'],
      };
    }).toList();
  }

  static Future<Map<String, dynamic>> createWorker(Map<String, dynamic> data,
      {String? imagePath}) async {
    final db = await DatabaseHelper.instance.database;
    final supId = await getSupervisorId();
    if (supId == null) throw AuthException('Not authenticated');

    String? savedPhotoPath;
    if (imagePath != null) {
      savedPhotoPath = await _savePhoto(imagePath);
    }

    // Compute BMI
    final weight = double.parse(data['weight'].toString());
    final height = double.parse(data['height'].toString());
    final bmi = weight / ((height / 100) * (height / 100));

    final id = await db.insert('workers', {
      'supervisorId': supId,
      'name': data['name'],
      'email': data['email'],
      'gender': data['gender'],
      'age': int.parse(data['age'].toString()),
      'weight': weight,
      'height': height,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'photoPath': savedPhotoPath,
    });

    return {
      '_id': id.toString(),
      'name': data['name'],
      'email': data['email'],
      'gender': data['gender'],
      'age': int.parse(data['age'].toString()),
      'weight': weight,
      'height': height,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'photoUrl': savedPhotoPath,
    };
  }

  static Future<Map<String, dynamic>> updateWorker(
      String id, Map<String, dynamic> data,
      {String? imagePath}) async {
    final db = await DatabaseHelper.instance.database;
    final supId = await getSupervisorId();
    if (supId == null) throw AuthException('Not authenticated');

    String? savedPhotoPath;
    if (imagePath != null) {
      savedPhotoPath = await _savePhoto(imagePath);
    }

    final weight = double.parse(data['weight'].toString());
    final height = double.parse(data['height'].toString());
    final bmi = weight / ((height / 100) * (height / 100));

    final updateData = <String, dynamic>{
      'name': data['name'],
      'email': data['email'],
      'gender': data['gender'],
      'age': int.parse(data['age'].toString()),
      'weight': weight,
      'height': height,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
    };

    if (savedPhotoPath != null) {
      updateData['photoPath'] = savedPhotoPath;
    }

    await db.update(
      'workers',
      updateData,
      where: 'id = ? AND supervisorId = ?',
      whereArgs: [int.parse(id), supId],
    );

    final result = await db.query('workers',
        where: 'id = ?', whereArgs: [int.parse(id)]);
    if (result.isEmpty) throw Exception('Worker not found');

    final row = result.first;
    return {
      '_id': row['id'].toString(),
      'name': row['name'],
      'email': row['email'],
      'gender': row['gender'],
      'age': row['age'],
      'weight': row['weight'],
      'height': row['height'],
      'bmi': row['bmi'],
      'photoUrl': row['photoPath'],
    };
  }

  static Future<bool> deleteWorker(String id) async {
    final db = await DatabaseHelper.instance.database;
    final supId = await getSupervisorId();
    if (supId == null) throw AuthException('Not authenticated');

    // Also delete associated records
    await db.delete('monitoring_records',
        where: 'workerId = ? AND supervisorId = ?',
        whereArgs: [int.parse(id), supId]);

    final count = await db.delete(
      'workers',
      where: 'id = ? AND supervisorId = ?',
      whereArgs: [int.parse(id), supId],
    );

    return count > 0;
  }

  // ── Records ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRecords(
      {String? workerId}) async {
    final db = await DatabaseHelper.instance.database;
    final supId = await getSupervisorId();
    if (supId == null) throw AuthException('Not authenticated');

    String whereClause = 'r.supervisorId = ?';
    List<dynamic> whereArgs = [supId];

    if (workerId != null) {
      whereClause += ' AND r.workerId = ?';
      whereArgs.add(int.parse(workerId));
    }

    final results = await db.rawQuery('''
      SELECT r.*, w.name as workerName
      FROM monitoring_records r
      LEFT JOIN workers w ON r.workerId = w.id
      WHERE $whereClause
      ORDER BY r.createdAt DESC
    ''', whereArgs);

    return results.map((row) {
      return {
        '_id': row['id'].toString(),
        'workerId': {
          '_id': row['workerId'].toString(),
          'name': row['workerName'],
        },
        'windSpeed': row['windSpeed'],
        'blackBallTemp': row['blackBallTemp'],
        'ambientTemp': row['ambientTemp'],
        'humidity': row['humidity'],
        'activityIntensity': row['activityIntensity'],
        'pulse': row['pulse'],
        'clothing': row['clothing'],
        'workDuration': row['workDuration'],
        'heatStressIndex': row['heatStressIndex'],
        'riskLevel': row['riskLevel'],
        'createdAt': row['createdAt'],
      };
    }).toList();
  }

  static Future<Map<String, dynamic>> createRecord(
      Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    final supId = await getSupervisorId();
    if (supId == null) throw AuthException('Not authenticated');

    final now = DateTime.now().toIso8601String();

    final id = await db.insert('monitoring_records', {
      'supervisorId': supId,
      'workerId': int.parse(data['workerId'].toString()),
      'windSpeed': data['windSpeed'],
      'blackBallTemp': data['blackBallTemp'],
      'ambientTemp': data['ambientTemp'],
      'humidity': data['humidity'],
      'activityIntensity': data['activityIntensity'],
      'pulse': data['pulse'],
      'clothing': data['clothing'],
      'workDuration': data['workDuration'],
      'heatStressIndex': data['heatStressIndex'],
      'riskLevel': data['riskLevel'],
      'createdAt': now,
    });

    return {
      '_id': id.toString(),
      ...data,
      'createdAt': now,
    };
  }

  // ── Photo Helper ──────────────────────────────────────────
  static Future<String> _savePhoto(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/worker_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final fileName =
        'photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = '${photosDir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
