import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_assistant_response.dart';

/// Callable Cloud Function `generateHealthAssistantResponse` — no Gemini in-app.
class HealthAssistantApiService {
  HealthAssistantApiService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Future<HealthAssistantResponse> sendMessage({
    required String uid,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw StateError('Not signed in or uid mismatch.');
    }

    await user.getIdToken(true);

    try {
      final callable = _functions.httpsCallable('generateHealthAssistantResponse');
      final result = await callable.call(<String, dynamic>{
        'uid': uid,
        'message': message,
      });

      final data = result.data;
      if (data is! Map) {
        throw FormatException('Unexpected response from assistant.');
      }
      final map = Map<String, dynamic>.from(
        data.map((k, v) => MapEntry(k.toString(), v)),
      );
      return HealthAssistantResponse.fromJson(map);
    } on FirebaseFunctionsException catch (e) {
      final code = e.code.toLowerCase();
      final msg = e.message;
      if (code == 'unauthenticated') {
        throw Exception(
          msg != null && msg.isNotEmpty
              ? msg
              : 'Sign-in was not accepted by the server. After deploying the '
                  'function, ensure it allows public invocation (Cloud Run '
                  'invoker) or sign out and sign in again.',
        );
      }
      if (msg != null && msg.isNotEmpty) {
        throw Exception(msg);
      }
      throw Exception(e.code);
    }
  }
}
