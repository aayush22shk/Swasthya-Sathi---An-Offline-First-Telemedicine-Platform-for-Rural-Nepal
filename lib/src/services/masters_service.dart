import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/specialization_model.dart';

class MastersService {
  MastersService._internal();
  static final MastersService _instance = MastersService._internal();
  factory MastersService() => _instance;

  List<SpecializationModel>? _cachedSpecializations;

  /// Fetch all medical specializations from the backend
  Future<List<SpecializationModel>> getSpecializations({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSpecializations != null && _cachedSpecializations!.isNotEmpty) {
      return _cachedSpecializations!;
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.specializations),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['specializations'] is List) {
          list = data['specializations'] as List;
        }

        final specs = list
            .map((item) => SpecializationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (specs.isNotEmpty) {
          _cachedSpecializations = specs;
          return specs;
        }
      }
    } catch (_) {}

    // Fallback list of common specializations
    return const [
      SpecializationModel(id: 1, name: 'General Physician'),
      SpecializationModel(id: 2, name: 'Cardiology'),
      SpecializationModel(id: 3, name: 'Obstetrics & Gynecology'),
      SpecializationModel(id: 4, name: 'Pediatrics'),
      SpecializationModel(id: 5, name: 'Dermatology'),
      SpecializationModel(id: 6, name: 'Orthopedics'),
      SpecializationModel(id: 7, name: 'Neurology'),
      SpecializationModel(id: 8, name: 'Psychiatry'),
    ];
  }
}
