import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseStorage _firebaseStorage;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? firebaseMessaging,
    FirebaseStorage? firebaseStorage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'algohary'),
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }

      // Fetch user from Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (!docSnapshot.exists) {
        // Auth exists but no Firestore profile yet (should happen during sign up)
        throw Exception('user-not-found');
      }

      var userModel = UserModel.fromJson(docSnapshot.data()!);

      // Update FCM Token unless it's Web
      if (!kIsWeb) {
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null && token != userModel.fcmToken) {
            await _firestore.collection('users').doc(user.uid).update({
              'fcm_token': token,
              'last_login_at': FieldValue.serverTimestamp(),
            });
            // Update local model
            userModel = UserModel(
              id: userModel.id,
              firstName: userModel.firstName,
              lastName: userModel.lastName,
              email: userModel.email,
              phone: userModel.phone,
              imageUrl: userModel.imageUrl,
              userType: userModel.userType,
              isActive: userModel.isActive,
              isBlocked: userModel.isBlocked,
              fcmToken: token,
              subscription: userModel.subscription,
              createdAt: userModel.createdAt,
              updatedAt: userModel.updatedAt,
              lastLoginAt: DateTime.now(),
            );
          } else {
             // Just update last login
             await _firestore.collection('users').doc(user.uid).update({
              'last_login_at': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          // Ignore FCM token errors (e.g. permission not granted)
          debugPrint('Error fetching FCM token: $e');
        }
      } else {
          // Just update last login on web
          await _firestore.collection('users').doc(user.uid).update({
          'last_login_at': FieldValue.serverTimestamp(),
        });
      }

      if (userModel.isBlocked) {
         throw Exception('user-blocked');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('user-not-found');
      } else if (e.code == 'wrong-password') {
        throw Exception('wrong-password');
      }
      throw Exception(e.message ?? 'An unknown error occurred');
    } catch (e) {
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
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      String imageUrl = '';
      if (profileImage != null) {
        final ref = _firebaseStorage.ref().child('avatars/${user.uid}.jpg');
        // readAsBytes works across all platforms including Web
        final bytes = await profileImage.readAsBytes();
        final uploadTask = await ref.putData(bytes);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      String? fcmToken;
      if (!kIsWeb) {
        try {
          fcmToken = await _firebaseMessaging.getToken();
        } catch (e) {
          debugPrint('Error fetching FCM token during signup: $e');
        }
      }

      final userModel = UserModel(
        id: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('email-already-in-use');
      }
      throw Exception(e.message ?? 'An unknown error occurred');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (!docSnapshot.exists) return null;

      var userModel = UserModel.fromJson(docSnapshot.data()!);

      if (!kIsWeb) {
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null && token != userModel.fcmToken) {
            await _firestore.collection('users').doc(user.uid).update({
              'fcm_token': token,
              'last_login_at': FieldValue.serverTimestamp(),
            });
            userModel = UserModel.fromJson({
              ...docSnapshot.data()!,
              'fcm_token': token,
            });
          }
        } catch (_) {}
      }
      return userModel;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
