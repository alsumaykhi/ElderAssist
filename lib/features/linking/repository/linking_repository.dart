import '../services/linking_service.dart';

class LinkingRepository {
  LinkingRepository({required LinkingService linkingService})
      : _linkingService = linkingService;

  final LinkingService _linkingService;

  Future<String> generateLinkCode(String caregiverUid) =>
      _linkingService.generateLinkCode(caregiverUid);

  Future<bool> validateAndLink({
    required String code,
    required String seniorUid,
  }) =>
      _linkingService.validateAndLink(code: code, seniorUid: seniorUid);
}
