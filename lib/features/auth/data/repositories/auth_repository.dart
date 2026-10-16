import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

/// Typed authentication error.
///
/// [toString] intentionally keeps the legacy `Exception: <code>` format so the
/// existing presentation layer (which strips the `Exception: ` prefix and
/// matches on the code) keeps working unchanged.
class AuthException implements Exception {
  final String code;
  const AuthException(this.code);

  @override
  String toString() => 'Exception: $code';
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseStorage _firebaseStorage;

  /// Firestore writes never complete while the device is offline, so every
  /// "best effort" write is bounded by this timeout to avoid hanging the UI.
  static const Duration _bestEffortTimeout = Duration(seconds: 5);

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? firebaseMessaging,
    FirebaseStorage? firebaseStorage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'algohary'),
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  /// Firebase Auth treats e-mail addresses case-insensitively, but Firestore
  /// queries are case-sensitive. Always store / query the canonical form.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Finds the Firestore profile of [user]: by uid first, then by e-mail
  /// (for profiles that were created manually with a different document id).
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserDoc(User user) async {
    final uidDoc = await _firestore.collection('users').doc(user.uid).get();
    if (uidDoc.exists && uidDoc.data() != null) return uidDoc;

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty && query.docs.first.data().isNotEmpty) {
        return query.docs.first;
      }
    }
    return null;
  }

  /// Builds a [UserModel] making sure the id always comes from the document id.
  UserModel _modelFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }

  Future<String> _uploadAvatar(String uid, XFile file) async {
    final ref = _firebaseStorage.ref().child('avatars/$uid.jpg');
    // readAsBytes works across all platforms including Web.
    final bytes = await file.readAsBytes();
    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _safeSignOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('AuthRepository: signOut failed: $e');
    }
  }

  /// Updates `last_login_at` and (on mobile) the FCM token. Never throws.
  Future<UserModel> _syncSessionData(
    DocumentReference<Map<String, dynamic>> ref,
    UserModel model,
  ) async {
    final updates = <String, dynamic>{
      'last_login_at': FieldValue.serverTimestamp(),
    };
    String? newToken;

    if (!kIsWeb) {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null && token != model.fcmToken) {
          updates['fcm_token'] = token;
          newToken = token;
        }
      } catch (e) {
        // e.g. notification permission not granted.
        debugPrint('Error fetching FCM token: $e');
      }
    }

    try {
      await ref.update(updates).timeout(_bestEffortTimeout, onTimeout: () {});
    } catch (e) {
      debugPrint('Error updating session data: $e');
    }

    return model.copyWith(
      fcmToken: newToken ?? model.fcmToken,
      lastLoginAt: DateTime.now(),
    );
  }

  String _mapSignInCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'user-not-found';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'wrong-password';
      case 'user-disabled':
        return 'user-blocked';
      default:
        return code;
    }
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
    bool isProvider = false,
  }) async {
    var signedIn = false;
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizeEmail(email),
        password: password,
      );
      signedIn = true;

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('auth-failed');
      }

      final userDoc = await _findUserDoc(user);
      if (userDoc == null) {
        // Auth account exists but there is no Firestore profile.
        await _safeSignOut();
        throw const AuthException('user-not-found');
      }

      final userModel = _modelFromDoc(userDoc);

      // Blocked users must be rejected BEFORE any write is attempted.
      if (userModel.isBlocked) {
        await _safeSignOut();
        throw const AuthException('user-blocked');
      }

      if (isProvider && userModel.userType != 'provider') {
        await _safeSignOut();
        throw const AuthException('not-a-provider');
      }

      return await _syncSessionData(userDoc.reference, userModel);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapSignInCode(e.code));
    } catch (e) {
      // Network / Firestore failure after a successful sign-in: do not leave
      // a half-authenticated session behind.
      if (signedIn) await _safeSignOut();
      throw Exception(e.toString());
    }
  }

  Future<UserModel> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    XFile? profileImage,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    User? createdUser;

    try {
      // Duplicate e-mails are rejected by Firebase Auth itself
      // (`email-already-in-use`). The previous pre-check queried the `users`
      // collection while still unauthenticated, which requires public read
      // access to every profile (PII leak) or fails with permission-denied.
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('auth-failed');
      }
      createdUser = user;

      // A failed avatar upload must not block account creation.
      String imageUrl = '';
      if (profileImage != null) {
        try {
          imageUrl = await _uploadAvatar(user.uid, profileImage);
        } catch (e) {
          debugPrint('Avatar upload failed during signup: $e');
        }
      }

      String? fcmToken;
      if (!kIsWeb) {
        try {
          fcmToken = await _firebaseMessaging.getToken();
        } catch (e) {
          debugPrint('Error fetching FCM token during signup: $e');
        }
      }

      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: normalizedEmail,
        phone: '', // Can be updated later
        imageUrl: imageUrl,
        userType: 'customer',
        isActive: true,
        isBlocked: false,
        fcmToken: fcmToken,
        subscription: Subscription(
          isSubscribed: false,
          isActive: false,
        ),
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());

      return userModel;
    } on AuthException {
      await _rollbackSignUp(createdUser);
      rethrow;
    } on FirebaseAuthException catch (e) {
      await _rollbackSignUp(createdUser);
      throw AuthException(e.code);
    } catch (e) {
      // Without the profile document the account would be unusable (login
      // reports "user-not-found" and sign-up reports "email-already-in-use"),
      // so remove the orphaned Auth account to let the user retry cleanly.
      await _rollbackSignUp(createdUser);
      throw Exception(e.toString());
    }
  }

  Future<void> _rollbackSignUp(User? createdUser) async {
    if (createdUser == null) return;
    try {
      await createdUser.delete();
    } catch (e) {
      debugPrint('AuthRepository: could not delete orphaned account: $e');
      await _safeSignOut();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final userDoc = await _findUserDoc(user);
      if (userDoc == null) return null;

      var userModel = _modelFromDoc(userDoc);

      // A user blocked while holding an active session must not stay signed in.
      if (userModel.isBlocked) {
        await _safeSignOut();
        return null;
      }

      if (!kIsWeb) {
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null && token != userModel.fcmToken) {
            await userDoc.reference
                .update({'fcm_token': token}).timeout(_bestEffortTimeout, onTimeout: () {});
            userModel = userModel.copyWith(fcmToken: token);
          }
        } catch (e) {
          debugPrint('Error refreshing FCM token: $e');
        }
      }
      return userModel;
    } catch (e) {
      debugPrint('AuthRepository.getCurrentUser error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final user = _firebaseAuth.currentUser;

    // Detach this device from the account so push notifications addressed to
    // the previous user are not delivered to whoever signs in next, and so the
    // provider is not left "online" on the map.
    if (user != null) {
      try {
        final doc = await _findUserDoc(user).timeout(_bestEffortTimeout);
        if (doc != null) {
          await doc.reference.update({
            'is_online': false,
            'fcm_token': FieldValue.delete(),
            'updated_at': FieldValue.serverTimestamp(),
          }).timeout(_bestEffortTimeout, onTimeout: () {});
        }
      } catch (e) {
        debugPrint('AuthRepository.logout cleanup failed: $e');
      }

      if (!kIsWeb) {
        try {
          await _firebaseMessaging.deleteToken().timeout(_bestEffortTimeout);
        } catch (e) {
          debugPrint('AuthRepository.logout deleteToken failed: $e');
        }
      }
    }

    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: normalizeEmail(email));
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw const AuthException('user-not-logged-in');
      }

      // Re-authenticate user
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw const AuthException('wrong-password');
        case 'weak-password':
          throw const AuthException('weak-password');
        case 'requires-recent-login':
          throw const AuthException('requires-recent-login');
        default:
          throw AuthException(e.message ?? e.code);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    XFile? profileImage,
    String? categoryId,
    List<String>? services,
    String? governorateId,
    List<String>? cities,
    String? about,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('user-not-logged-in');
      }

      // Same lookup as every other method (uid first, then e-mail fallback);
      // the old code always updated `users/{uid}` and failed for profiles whose
      // document id differs from the Auth uid.
      final userDoc = await _findUserDoc(user);
      if (userDoc == null) {
        throw const AuthException('user-not-found');
      }

      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await _uploadAvatar(user.uid, profileImage);
      }

      final updateData = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (categoryId != null) updateData['category_id'] = categoryId;
      if (services != null) updateData['services'] = services;
      if (governorateId != null) updateData['governorate_id'] = governorateId;
      if (cities != null) updateData['cities'] = cities;
      if (about != null) updateData['about'] = about;

      if (imageUrl != null) {
        updateData['image_url'] = imageUrl;
      }

      await userDoc.reference.update(updateData);

      final fresh = await userDoc.reference.get();
      return _modelFromDoc(fresh);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return _modelFromDoc(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user by id: $e');
      return null;
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw const AuthException('user-not-logged-in');

      final userDoc = await _findUserDoc(user);
      if (userDoc == null) throw const AuthException('user-not-found');

      await userDoc.reference.update({
        'is_online': isOnline,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
