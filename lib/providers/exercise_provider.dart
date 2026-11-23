import 'package:flutter/foundation.dart';
import '../data/models/exercise_model.dart';
import '../data/repositories/exercise_repository.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _repository;

  List<ExerciseCategory> _categories = [];
  List<ExerciseModel> _exercises = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isFromApi = true;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 30;
  String? _error;

  ExerciseProvider({required ExerciseRepository repository})
      : _repository = repository;

  List<ExerciseCategory> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isFromApi => _isFromApi;
  bool get hasMore => _hasMore && _isFromApi;
  String? get error => _error;

  List<ExerciseModel> get filteredExercises {
    if (_searchQuery.trim().isEmpty) return _exercises;
    final q = _searchQuery.trim().toLowerCase();
    return _exercises.where((e) {
      final inName = e.name.toLowerCase().contains(q);
      final inCat = e.category.name.toLowerCase().contains(q);
      final inMuscle =
          e.muscles.any((m) => m.displayName.toLowerCase().contains(q));
      final inEquip = e.equipment.any((eq) => eq.toLowerCase().contains(q));
      return inName || inCat || inMuscle || inEquip;
    }).toList();
  }

  Future<void> initialize() async {
    if (_exercises.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
      final result = await _repository.getExercises(
        limit: _pageSize,
        offset: 0,
        categoryId: _selectedCategoryId,
      );
      _exercises = result.items;
      _isFromApi = result.isFromApi;
      _offset = result.items.length;
      _hasMore = result.items.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _offset = 0;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getExercises(
        limit: _pageSize,
        offset: 0,
        categoryId: _selectedCategoryId,
      );
      _exercises = result.items;
      _isFromApi = result.isFromApi;
      _offset = result.items.length;
      _hasMore = result.items.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || !_isFromApi) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.getExercises(
        limit: _pageSize,
        offset: _offset,
        categoryId: _selectedCategoryId,
      );
      if (result.items.isEmpty) {
        _hasMore = false;
      } else {
        _exercises = [..._exercises, ...result.items];
        _offset += result.items.length;
        _hasMore = result.items.length >= _pageSize;
      }
    } catch (_) {
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
