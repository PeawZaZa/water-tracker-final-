import 'package:flutter/foundation.dart';
import '../models/water_log.dart';
import '../models/drink_type.dart';
import '../services/database_service.dart';

class WaterLogProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<WaterLog> _logs = [];
  List<DrinkType> _drinkTypes = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;
  String _selectedDate = '';
  String _selectedDrinkType = 'ทั้งหมด';

  List<WaterLog> get logs => _logs;
  List<DrinkType> get drinkTypes => _drinkTypes;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String get selectedDate => _selectedDate;
  String get selectedDrinkType => _selectedDrinkType;

  List<String> get drinkTypeNames {
    return ['ทั้งหมด', ..._drinkTypes.map((t) => t.name)];
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadDrinkTypes();
    await loadLogs();
    await loadDashboard();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDrinkTypes() async {
    _drinkTypes = await _db.getDrinkTypes();
    notifyListeners();
  }

  Future<void> loadLogs() async {
    _logs = await _db.searchLogs(
      date: _selectedDate.isEmpty ? null : _selectedDate,
      drinkType: _selectedDrinkType == 'ทั้งหมด' ? null : _selectedDrinkType,
    );
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _dashboardStats = await _db.getDashboardStats();
    notifyListeners();
  }

  void setDateFilter(String date) {
    _selectedDate = date;
    loadLogs();
  }

  void setDrinkTypeFilter(String type) {
    _selectedDrinkType = type;
    loadLogs();
  }

  void clearFilters() {
    _selectedDate = '';
    _selectedDrinkType = 'ทั้งหมด';
    loadLogs();
  }

  Future<bool> addLog(WaterLog log) async {
    try {
      await _db.insertLog(log);
      await loadLogs();
      await loadDashboard();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLog(WaterLog log) async {
    try {
      await _db.updateLog(log);
      await loadLogs();
      await loadDashboard();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLog(int id) async {
    try {
      await _db.deleteLog(id);
      await loadLogs();
      await loadDashboard();
      return true;
    } catch (e) {
      return false;
    }
  }

  DrinkType? getDrinkTypeByName(String name) {
    try {
      return _drinkTypes.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }
}
