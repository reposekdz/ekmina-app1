import 'dart:convert';
import 'package:flutter/services.dart';

class RwandaLocation {
  static Map<String, dynamic>? _data;

  static Future<void> initialize() async {
    final String jsonString = await rootBundle.loadString('Rwanda/data.json');
    _data = json.decode(jsonString);
  }

  static List<String> getProvinces() {
    return _data?.keys.toList() ?? [];
  }

  static List<String> getDistricts(String province) {
    final provinceData = _data?[province];
    return provinceData?.keys.toList() ?? [];
  }

  static List<String> getSectors(String province, String district) {
    final districtData = _data?[province]?[district];
    return districtData?.keys.toList() ?? [];
  }

  static List<String> getCells(String province, String district, String sector) {
    final sectorData = _data?[province]?[district]?[sector];
    return sectorData?.keys.toList() ?? [];
  }

  static List<String> getVillages(String province, String district, String sector, String cell) {
    final cellData = _data?[province]?[district]?[sector]?[cell];
    return List<String>.from(cellData ?? []);
  }

  static bool validateLocation(String province, String district, String sector, String cell, String village) {
    final villages = getVillages(province, district, sector, cell);
    return villages.contains(village);
  }
}
