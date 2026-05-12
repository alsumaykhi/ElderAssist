import 'package:flutter/foundation.dart';

import '../repository/linking_repository.dart';

class LinkingProvider extends ChangeNotifier {
  LinkingProvider({required LinkingRepository linkingRepository})
      : _linkingRepository = linkingRepository;

  final LinkingRepository _linkingRepository;

  String? _generatedCode;
  String? get generatedCode => _generatedCode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _linkSuccess = false;
  bool get linkSuccess => _linkSuccess;

  Future<void> generateLinkCode(String caregiverUid) async {
    _isLoading = true;
    _errorMessage = null;
    _generatedCode = null;
    _linkSuccess = false;
    notifyListeners();

    try {
      _generatedCode =
          await _linkingRepository.generateLinkCode(caregiverUid);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Failed to generate code. Please try again.';
      _generatedCode = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateAndLink({
    required String code,
    required String seniorUid,
  }) async {
    if (code.trim().length != 6) {
      _errorMessage = 'Please enter a 6-digit code.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _linkSuccess = false;
    notifyListeners();

    try {
      final success = await _linkingRepository.validateAndLink(
        code: code.trim(),
        seniorUid: seniorUid,
      );

      if (success) {
        _linkSuccess = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Invalid or already used code. Please try again.';
      }
      return success;
    } catch (_) {
      _errorMessage = 'Linking failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearGeneratedCode() {
    _generatedCode = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearLinkResult() {
    _linkSuccess = false;
    _errorMessage = null;
    notifyListeners();
  }
}
