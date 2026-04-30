import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<String> _getGoogleIdToken() async {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception("Google sign in cancelled");
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception("Google ID token not found");
    }

    return idToken;
  }

  static Future<Response> signInWithGoogle({
    required String requestedRole,
    required double lat,
    required double lng,
  }) async {
    final idToken = await _getGoogleIdToken();

    return DioClient.dio.post(
      "/api/auth/google",
      data: {
        "idToken": idToken,
        "requestedRole": requestedRole,
        "location": {
          "type": "Point",
          "coordinates": [lng, lat],
        },
      },
    );
  }

  static Future<Response> loginWithGoogle() async {
    final idToken = await _getGoogleIdToken();

    return DioClient.dio.post(
      "/api/auth/google",
      data: {
        "idToken": idToken,
      },
    );
  }

  static Future<Response> completeWorkerProfile({
    required String bio,
    required int yearsOfExperience,
    required List<String> skills,
  }) {
    return DioClient.dio.post(
      "/api/auth/google/worker-profile",
      data: {
        "bio": bio,
        "yearsOfExperience": yearsOfExperience,
        "skills": skills,
      },
    );
  }
}