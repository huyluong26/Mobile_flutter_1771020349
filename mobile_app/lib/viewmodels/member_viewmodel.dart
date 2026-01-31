import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../models/paged_result.dart';
import '../services/api_service.dart';

/// Member list state
enum MemberListState { initial, loading, loaded, error }

/// Member ViewModel for admin member management
class MemberViewModel extends ChangeNotifier {
  MemberListState _state = MemberListState.initial;
  List<Member> _members = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;
  String? _searchQuery;
  String? _tierFilter;
  String? _errorMessage;

  // Getters
  MemberListState get state => _state;
  List<Member> get members => _members;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();
  bool get isLoading => _state == MemberListState.loading;
  String? get errorMessage => _errorMessage;

  /// Load members with optional search and filter
  Future<void> loadMembers({
    String? search,
    String? tier,
    int page = 1,
    bool refresh = false,
  }) async {
    if (refresh) {
      _members = [];
      _currentPage = 1;
    }

    _state = MemberListState.loading;
    _searchQuery = search;
    _tierFilter = tier;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiService.getMembers(
        search: search,
        tier: tier,
        page: page,
        pageSize: _pageSize,
      );

      _members = result.items;
      _totalCount = result.totalCount;
      _currentPage = result.pageNumber;
      _state = MemberListState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = MemberListState.error;
    }
    notifyListeners();
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (_currentPage < totalPages) {
      await loadMembers(
        search: _searchQuery,
        tier: _tierFilter,
        page: _currentPage + 1,
      );
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await loadMembers(
        search: _searchQuery,
        tier: _tierFilter,
        page: _currentPage - 1,
      );
    }
  }

  /// Refresh list
  Future<void> refresh() async {
    await loadMembers(
      search: _searchQuery,
      tier: _tierFilter,
      page: 1,
      refresh: true,
    );
  }
}
