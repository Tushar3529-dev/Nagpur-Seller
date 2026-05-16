import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebasePhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Send OTP to the provided phone number
  Future<String> sendOTP({
    required String phoneNumber,
    required Function(String error) onError,
    Function? onAutoVerify,
  }) async {
    final completer = Completer<String>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
          debugPrint('Auto verification completed');
          if (onAutoVerify != null) {
            onAutoVerify();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          onError(errorMessage);
          if (!completer.isCompleted) {
            completer.completeError(errorMessage);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Code sent to $phoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout');
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );
      return completer.future;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      onError(e.toString());
      rethrow;
    }
  }

  /// Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      debugPrint('OTP verified successfully');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verification failed: ${e.message}');
      if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid OTP. Please try again');
      } else if (e.code == 'session-expired') {
        throw Exception('OTP expired. Please request a new one');
      } else {
        throw Exception(e.message ?? 'OTP verification failed');
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      throw Exception('Failed to verify OTP');
    }
  }

  /// Resend OTP
  Future<String> resendOTP({
    required String phoneNumber,
    required Function(String error) onError,
  }) async {
    final completer = Completer<String>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto verification completed on resend');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Resend verification failed: ${e.message}');
          onError(e.message ?? 'Failed to resend OTP');
          if (!completer.isCompleted) {
            completer.completeError(e.message ?? 'Failed to resend OTP');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP resent to $phoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );
      return completer.future;
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      onError(e.toString());
      rethrow;
    }
  }

  /// Get current verification ID
  String? get verificationId => _verificationId;

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;
}
